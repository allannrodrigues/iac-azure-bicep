# Azure IaC with Bicep - Resource Provisioning Guide by VSCODE

This guide will help you deploy resources on **Microsoft Azure** using **Bicep** within **Visual Studio Code**. Ensure that Visual Studio Code is connected to an account with **Contributor** privileges on the Azure subscription.

## Prerequisites
- **Visual Studio Code** installed
- **Bicep extension** for Visual Studio Code
- **Azure account** with Contributor access to the subscription
- An active **Azure subscription**


## Step 1: Fill in Variables in the `configs.bicepparam` File
Before proceeding, open the `configs.bicepparam` file in Visual Studio Code. Fill in the required variables, such as the resource location, resource names, and any other necessary parameters. This file will be used for configuring the deployment.

## Step 2: (Optional) Create a Resource Group
You can either:

- **Use the `resource-group-main.bicep` file**:
   - Open the `resource-group-main.bicep` file in Visual Studio Code.
   - Run the Bicep file directly in Visual Studio Code using the **Rigth Click** and chosing **Deploy Bicep File**.

## Step 3: Creates Resources

Before creating you can modify the script as you want.

- **Use the `resources-main.bicep` file**:
   - Open the `resources-main.bicep` file in Visual Studio Code.
   - Run the Bicep file directly in Visual Studio Code using the **Rigth Click** and chosing **Deploy Bicep File**.
   - Chose or create the **Resource Group** and select **Deploy Bicep File**  with **Rigth Click**.
   - In output from **VsCode** select **Bicep Operations** and you can a link to **Deployment in portal Azure**.
