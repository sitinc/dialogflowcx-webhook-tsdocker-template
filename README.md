# Overview


This application template project enables you to get started with Dialogflow CX connected into features that usually require more effort to get going, including webhooks, interaction logging for analytics, audio recording, data privacy, disaster recovery and version/environment control, and secret management.

The project contains infrastructure as code (IaC) and the Typescript/Javascript source files for the main API gateway to handle Webhook fulfillment requests from Dialogflow CX.  To simplify some of the boiler plate of integrating ExpressJS with Dialogflow CX "tag" webhooks, the @sitinc/dialogflowcx-tagexpress enables simply Express Router-style refinitions of webhook "tag" similar to URL paths with standard Express endpoints.

Here is a look at the solution architecture generated from this project template.

![Project Template Solution Arch!](/docs/assets/20240324-project-solution-arch.png "Project Template Solution Arch")

The Terraform IaC files will create all of the necessary infrastructure on Google Cloud Platform, and add a backup-restore repository to GitHub.  Below is a full list of the changes:

Shared Project Resources:
 - Artifact Registry: Storage for Docker images for Cloud Run
 - GitHub Repo: Backup-Restore repo for Dialogflow CX Agent
 - Data Loss Prevension (DLP) Inspection, De-identify, and Dialogflow CX Configuration
 - Storage Buckets for Terraform state, Audio Recordings for All Voice Calls, and Artifact Registry

Per-Environment ("main" and "uat") Project Resources:
 - Dialogflow CX Agent
 - Cloud Run: ExpressJS Dialogflow CX Webhook Fulfillment API Gateway
 - Cloud Build Trigger: GitHub -> Build & Test -> Artifact Registry -> Cloud Run

Dedicated services accounts (SAs) are used for cloud run, and least possible priviledges as assigned to it and service-specific SAs like cloud build and Dialogflow CX.  Custom HTTP username and password headers are used between Cloud Run Webhooks and Dialogflow CX, all managed by Terraform.

Multiple environments are managed under a single branch to simplify the inter-referencing of configurations.  The expected behaviour of multi-brand IaC is that both the "main" branch and "uat" branch would each have "main" and "uat" resources for their GCP project-isolated environments.


# Before Getting Started


Before we get started, you'll need the following setup.

 - [Create a Google Cloud Platform account](https://console.cloud.google.com/getting-started?pli=1), with billing enabled.  The resources created by this project should not contribute anything meaningful in terms of costs if used by a single developer for testing purposes.
 - [Create a user account on GitHub](https://docs.github.com/en/get-started/start-your-journey/creating-an-account-on-github), free tier is fine.
 - [Install the Cloud Build GitHub App](https://github.com/apps/google-cloud-build) under the GitHub user account you will use to clone this repository.  After installing the app, on your profile, go to *Settings-> (Integrations) Applications*, then click on *Configure* for the *Google Cloud Build* entry.  NOTE DOWN the numeric ID at the end of the URL (i.e. for "https://github.com/settings/installations/12345678", write down *12345678* - this is the *Cloud Build GitHub App ID* and we'll need it later).
 - [Create a GitHub API token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) that has access to manage app connections and repositories.
 - [Install Terraform](https://developer.hashicorp.com/terraform/install) on your dev workstation.
 - [Install gcloud CLI](https://cloud.google.com/sdk/docs/install) on your dev workstation.  It will be used to create some resources ahead of running Terraform, suchs as the storage bucket used by Terraform as a backend.
 - Install Git and be familiar with an IDE or working with version controlled projects.  I use VSCode for working with projects created from this template.
 - (Optional) [Create a NPMJS user account](https://docs.npmjs.com/getting-started/setting-up-your-npm-user-account) if you plan to use private NPM packages from NPMJS*.  
 - (Optional) [Create a NPMJS API token](https://docs.npmjs.com/creating-and-viewing-access-tokens) if you plan to use private NPM packages from NPMJS*.

\* The template projects assumes this environment, but it shouldn't matter if you only plan on using public packages.  Simply enter any random string when prompted to input the NPM API token during the relevant stage.


# Getting Started


With the pre-requisites out of the way, we're ready to get started.  The next few steps might require some adjustments based on how you like to work.

 - **GitHub**: Web UI, but feel free to adjust to CLI if you prefer.
 - **Shell**: Local bash on my dev workstation.
 - **IDE**: VSCode on my dev workstation.


## Create the Project Application Github Repository

### Create a new repo based on this template

The next few steps might require some adjustments based on how you like to work.  I'm going to show the steps from the perspective of the GitHub web UI, but feel free to use the CLI (along with even Google cloud shell) if you prefer.  The first step is to create a new repo based on this template repo.


![Selecting Create a Repository from a template!](/docs/assets/20240324-new-repo-from-template.png "Create Repository From Template")

You can use whatever you like for the repository name, but I'm going to match it up with what we'll call the *application name*.  For our example, let's use **test-cxagent1**.

![Configure the Repository!](/docs/assets/20240324-new-repo-values.png "Configure the Repository")

Click on *Create repository* when you're ready.

You should now have a repository in the form of \<*owner*>/\<*repo-name*>.  For my user **justin-oos** and repo name **test-cxagent1**, that would be **justin-oos/test-cxagent1**.


### Checkout the Project Application Repository


Use your preferred git interface.  Depending on which application I'm using, I have different preferences for Git interfaces.  When I'm checking out a repository locally on a Windows machine, I prefer to use [Tortoise Git](https://tortoisegit.org/) within File Explorer.

![File Explorer Git Clone!](/docs/assets/20240324-git-clone-explorer.png "File Explorer Git Clone")

![Git Clone New Repo!](/docs/assets/20240324-git-clone-url.png "Git Clone New Repo")


## Create the Main Application Google Cloud Project

Alright, now let's login to the [Google Cloud Console](https://console.cloud.google.com).  

### Creating the GCP project instance.

Search for *Manage Resources* in the cloud console search bear.  Select the top matching entry from the results and click on *CREATE PROJECT*.

![Manage Resources Create Project!](/docs/assets/20240324-gcp-managed-resources.png "Manage Resources Create Project")

![Create GCP Project!](/docs/assets/20240324-gcp-create-project.png "Create GCP Project")


## Building the Project Application Infrastructure

Now that the project is ready, it's time to start building!


### Loading and Initializing the Local Project

Let's load the newly created and checked out GitHub project in VSCode.

Launch a Bash terminal within the project directory.

The first step is to ensure you're logged into the GCloud CLI.

```bash
gcloud auth login
```

After logging in, switch to the **iac** project directory and run the **_init_tf_backend.sh** script.

```bash
cd iac
./_init_tf_backend.sh
```

Respond to all of the prompts with the correct details we've collected to date.


 ![GCloud and Project init!](/docs/assets/20240324-vscode-gcloud-and-init.png "GCloud and Project init")

Part of the output of the **_init_tf_backend.sh** script is a secrets file (don't worry, the level of sensitivity of the data within is low, and .gitignore will prevent it from ever being checked in.).  We'll reference that secrets file as we leverage Terraform to create our infrastructure.

The secrets file does have elements you'll want to customize, such as the following defaults:

```bash
# Project Overview
company_name = "Company ABC Inc."
contact_name = "The Author"
contact_url = "https://web.site"
contact_email = "author@web.site"
app_license = "MIT"
```

### Building the Project Application Infrastructure

Alright, now for the fun part - letting infrastructure create itself.



Let's start with **terraform init**

```bash
terraform init
```

 ![Terraform init!](/docs/assets/20240324-vscode-terraform-init.png "Terraform init")

Now let's create a plan for our changes with **terraform plan**

```bash
terraform plan -out .terraform.plan --var-file=secret.tfvars
```

 ![Terraform plan!](/docs/assets/20240324-vscode-terraform-plan.png "Terraform plan")

Everything should complete successfully, with an indication of the number of components that should be created.

If no errors occurred, let's apply the plan.

```bash
terraform apply ".terraform.plan"
```

 ![Terraform apply!](/docs/assets/20240324-vscode-terraform-apply.png "Terraform apply")

 You've just completed 95% of the effort in creating service accounts, permissions, API secrets, docker images, and so much more.


## Post-Build Configuration and Clean-up

 Though we've accomplish much, there are a few pieces left do to manually to clean things up and tie together some components without APIs to date.

### Checking-in Terraform-updated Project Files

 You may have noticed that running **terraform apply** has updated a few files locally.

 ```bash
 iac/tf_backend.tf
 src/swagger-json
 static/tos.txt
 ```

 Commit them back to the Git repository using your IDE or CLI.

  ```bash
git commit -m "Checking in project files updated by terraform."
 ```

The one that is critical to check-in is iac/tf_backend.tf, but the others ensure that Swagger UI username/password header authentication will work correctly, and that the Terms of Service denying all access will have the correct company name.

### Configure Dialogflow CX Advanced Agent Settings

There are a few settings we can't currently configure with Terraform and GCP today.

Let's navigate to the [Dialogflow CX Console](https://dialogflow.cloud.google.com/cx/projects/).  Search and select the GCP project we created.  You should see three agents created.

 ![GCP Project Agents!](/docs/assets/20240324-gcp-project-agents.png "GCP Project Agents")

Technically, the "-dev" one is only created to solve a race condition issue creating the first Dialogflow CX agent with DLP enabled.  It won't be used, won't contribute to cost, but don't delete it.  I'll refactor the IaC eventually to solve this problem and ensure no extra resource is left over.

Let's click in to the production (the first) agent.  Once the agent is loaded, go to *Agent settings* in the upper right corner.

On the *General* page, we're going to select various options.  For the BigQuery dataset and table, have no fear, they are already created, and you should be able to simply select them from the drop-down once you enable conversation history and bigquery export.

 - Enable Conversation History
 - Enable BigQuery export
   - Project name
   - BigQuery dataset
   - BigQuery table
 - Enable Intent Suggestions
 - Enable user feedback

  ![GCP CX Agent General Settings!](/docs/assets/20240324-gcp-agent-settings-general.png "GCP CX Agent General Settings")

Click *Save*

Remaining in *Agent settings*, navigate to *Speech and IVR*.

 - Select **Enable advanced speech settings**.
 - Set the Model to *Phone Call*.
 - Note the *Audio export bucket* is configured.

![GCP CX Agent IVR Settings!](/docs/assets/20240324-gcp-agent-settings-ivr.png "GCP CX Agent IVR Settings")

Click *Save*

**NOTE:**
REPEAT for "-uat" Dialogflow CX Agent.  These settings do not synchronize with backups.

### Verifying the Webhooks

Let's make sure the webhooks we have setup are working as we expect.

On the left-side navigation of the Dialogflow CX UI, under **Build**, select *Default Start Flow*.  That should load the Default Start Flow flow in the right-side canvas UI.

 - Click on *Default Welcome Intent*.  
 - Scroll down to **Parameter presets**, expand it, and click *Add parameter*.
   - Add the parameter **api_name** with the value of your name.
 - Scroll down to **Webhook settings**, expand it, toggle *Enable webhook* to "on", select *main-webhook* from the drop-down, and enter the value *New* as the tag.
 - Click *Save*
 - Open the **Test Agent** console on the right-side of the page.
   - In the *Talk to agent* field at the bottom, enter "Hello!" and send the message.

The console should show a response context parameter, api_msg, that contains a "Hello, {api_name}!" response that comes from the API backend.  Everything is connected!

![GCP CX Agent Test Agent!](/docs/assets/20240324-gcp-agent-webhook-test.png "GCP CX Agent Test Agent")

### Push the initial CX Agent Config to GitHub

We're now going to push the Dialogflow CX assets into GitHub as the first point-in-time recovery for backup-restore purposes.

The GitHub connection is already setup and ready to go.  On the left-side navigation of the Dialogflow CX UI, under **Manage->Testing & Deployment**, select *Git*

Click *Push*, provide a commit message like "Initial commit", then click *Push*.

![GCP CX Agent Git Push!](/docs/assets/20240324-gcp-agent-git.png "GCP CX Agent Git Push")

You've just taken your first agent backup using GitHub!

### Creating and Restoring the UAT Branch for Dialogflow CX

Part of the configuration and software development version control involves using a separate branch in GitHub.  Terraform has already configured the UAT Dialogflow CX to refer to a "uat" branch.

Now that we've pushed our initial CX configuration assets into GitHub.  Let's create the UAT branch.

 - Login to GitHub on the CX Agent backup-restore Project (\<*app-name*>-cx-dr).  For example, *test-cxagent1-cx-dr*
 - Click on *Branch*
 - Click on *New branch*
 - Enter "uat" in the *New branch name* and click *Create new branch*

![GCP CX Agent Git uat Branch!](/docs/assets/20240324-git-uat-branch.png "GCP CX Agent Git uat Branch")

Now let's navigate back to the [Dialogflow CX Console](https://dialogflow.cloud.google.com/cx/projects/) and select our "-uat" agent.

On the left-side navigation of the Dialogflow CX UI, under **Manage->Testing & Deployment**, select *Git*

Click *Restore*, then click *Restore* again to confirm.

![GCP CX Agent Git restore!](/docs/assets/20240324-gcp-agent-git-restore.png "GCP CX Agent Git restore")

You've just restore your first production agent backup to UAT using GitHub!

The flow I like to work from then on involves making changes in the "uat" agent/branch, the issuing pull requests to the "main" branch, upon which production changes will be released.  The pull request is convinient to review the bulk list of changes from one "release" to another.

 - Open the **Test Agent** console on the right-side of the page.
   - In the *Talk to agent* field at the bottom, enter "Hello!" and send the message.

The console should show a response context parameter, api_msg, that contains a "Hello, {api_name}!" response that comes from the API backend.  Everything is connected in UAT also!

![GCP CX Agent UAT test!](/docs/assets/20240324-gcp-agent-webhook-test-uat.png "GCP CX Agent UAT test")

### Verifying BigQuery Interaction Logging


Lastly, let's make sure BigQuery 

 - Login to the [BigQuery console](https://console.cloud.google.com/bigquery)
 - Select the GCP application project.
 - Expand the dataset to reach the **interaction_logs** table.
 - Click the options for the **interaction_logs** table and select *Query*.
 - In the query editor, place a "*" between the *SELECT* and the *FROM*.
 - Click *Run* to run the query.

You should see one entry for each test we did earlier.  One for the main agent and one for uat.

![GCP CX Agent BigQuery!](/docs/assets/20240324-bigquery.png "GCP CX Agent BigQuery")

You can now make use of this data for analytics purposes.

# Summary

We did it!  You should have a running Hello world example with plenty of room to expand to build the next virtual agent of your dreams... ;)

You should now have two GitHub repos:

 - The one you created based on this template.  For my example, **test-cxagent1**.
   - Manage infrastructure as code with Terraform in the **iac** directory.
   - Develop the API webhook gateway with Typescript/Javascript in the **src** directory.
 - The one created for backup-restore purposes with Dialogflow CX agents.  For my example, **test-cxagent1-cx-dr**.

The next step... connecting Dialogflow CX to your service channels!
