# Notes on Good practice
Though this project is not developed with patient data in mind, following **Good Practice** is a good habit to have. 
Following these principles requires mindfullness on standards, safe data handling, reproducibility and auditability.

## Data Security
Patient or client data anonymity:
+ Whether you are analysing patient data, data derived from consenting patients for science, researcher data or industry data... anonymity/pseudonymity should be followed.
Data storage:
+ Traditionally this means keeping data on a secure system, either locally or on a highly secure cloud system
+ It requires encryption of data.
+ If data is highly secure, you may need to consider air-gapped systems.
Controlled access:
+ This means read/write restrictions
+ It also means putting in place failsafes to prevent deletion of raw data by accident or malice
Secure deletion:
+ As with the previous point, deletion of critical data that cannot be replaced is not acceptable
+ Systems should be in place to prevent this.
+ But cleanliness also helps prevent this. Keeping inputs in one location, intermeiary in another, and outputs in a third allow clear delimination of what is safe to remove.
+ Set audit logs and automated cleaning/backing up

## Reproducibility
Containerised workflows
+ Whether using Singularity, Docker, Conda environments or local modules, containers preserve working reproducable programs
Workflow language
+ While this repo is built around a single shell and SLURM script, it contains lots of logging information and use of containers.
+ Other tools like Nextflow do allow greater scalability as well as modularity
Version control
+ This is important on your own, but vital when working as a group.
+ Not only does this allow for auditability and accountability, but it also allows for testing on forked repositories. Preserving functioning safe main repos.

## Testing & validation
+ When testing this normally involves stages such as dry-runs, subseting of samples, and heavy use of error logging.
+ It also means collecting of extensive metrics to compare and contrast against existing validated pipelines

## Documentation
+ This is important not only to remind you as a user but also inform others of your action and expectations of code.
+ Clear documentation should allow anyone to replicate how a pipeline runs, problem solve where an issue is occuring and adapt to improve.
+ Documentation comes within scripts and outside, for example this markdown!

## Compliance
+ Especially important in clinical settings, e.g. UKAS
+ As it is important in patient derrived samples. i.e. It is legally imperative to adhere to consent agreements. That may affect where you can publish results.

### Accreditation
| **Area**                 | **Requirement**                      | **Documented Evidence**    |
| Data traceability        | Sample → Result with audit trail     | Folder structure, logs     |
| Pipeline validation      | Sensitivity, specificity, LoD        | Validation report          |
| Change control           | Review, test, sign-off for changes   | Change log, SOP updates    |
| Information governance   | Security, anonymisation, data access | IG checklist, access logs  |
| Workflow reproducibility | Fixed versions, container use        | Git tags, Singularity defs |
| QC and reporting         | Automated checks, thresholds         | MultiQC, report templates  |
| Staff competency         | Training, CPD, SOP knowledge         | Training log, certificates |
