on:
  push:
    branches:
    - main

permissions:
  id-token: write
  contents: read

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3

    - name: Setup Node.js environment
      uses: actions/setup-node@v3.4.1
      with:
        node-version: 18.x
        
    - name: install ADF Utilities package
      run: npm install
      working-directory: ${{github.workspace}}/ADFroot/build
        
    - name: Validate
      run: npm run build validate ${{github.workspace}}/ADFroot/ /subscriptions/d0267b2e-22f4-4ff1-9803-75190ac401a6/resourceGroups/test-reg/providers/Microsoft.DataFactory/factories/DEV-ADF-FM
      working-directory: ${{github.workspace}}/ADFroot/build


    - name: Validate and Generate ARM template
      run: npm run build export ${{github.workspace}}/ADFroot/ /subscriptions/d0267b2e-22f4-4ff1-9803-75190ac401a6/resourceGroups/test-reg/providers/Microsoft.DataFactory/factories/DEV-ADF-FM "ExportedArmTemplate"
      working-directory: ${{github.workspace}}/ADFroot/build

    - name: upload artifact
      uses: actions/upload-artifact@v3
      with:
        name: ExportedArmTemplate
        path: ${{github.workspace}}/ADFroot/build/ExportedArmTemplate

  release:
    needs: build
    runs-on: ubuntu-latest
    steps:
    - name: Download a Build Artifact
      uses: actions/download-artifact@v3.0.2
      with:
        name: ExportedArmTemplate

    - name: Login via Az module
      uses: azure/login@v1
      with:
        client-id: ${{ secrets.AZURE_CLIENT_ID }}
        tenant-id: ${{ secrets.AZURE_TENANT_ID }}
        subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
        enable-AzPSSession: true 

    - name: Install Terraform
      run: |
        sudo apt-get update
        sudo apt-get install -y gnupg software-properties-common curl
        curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
        sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
        sudo apt-get update && sudo apt-get install terraform

    - name: List Directory Contents
      run: ls -al ${{ github.workspace }}/terraform

    - name: Terraform Init
      run: terraform init
      working-directory: ${{github.workspace}}/terraform

    - name: Terraform Plan
      run: terraform plan -out=tfplan
      working-directory: ${{github.workspace}}/terraform

    - name: Terraform Apply
      run: terraform apply -auto-approve tfplan
      working-directory: ${{github.workspace}}/terraform

    - name: data-factory-deploy
      uses: Azure/data-factory-deploy-action@v1.2.0
      with:
        resourceGroupName: prod
        dataFactoryName: prod_adf
        armTemplateFile: ARMTemplateForFactory.json
        armTemplateParametersFile: ARMTemplateParametersForFactory.json
        additionalParameters: "factoryName=prod_adf"
