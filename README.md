# 1CI
Repository manager for 1C: Enterprise platform. The main idea of the project - continuous integration.

# The main idea

When you develop configuration in a team, you often need to do some
routine operations, such as for example:

-   Everyday dumping of configuration from a repository and sending the
    result to partners;
-   Do many different tests, standard module check for example or some
    tests that could be made by some special software;
-   Informing your partners and coworkers about found errors in the
    configuration by email or IM like Skype or Telegram.
-   Load new version of the configuration into working database.

So this project (configuration) is intended for automation such things.
The part of the name of the project is abbreviation from Continuous
Integration, which is a reference to the conception that was
inspirational idea for the project.

# General description.

Configuration: independent, without necessity of integration;

Platform: 8.3;

Interface: Taxi;

Subsystems Library (SSL): 2.2.4.4 (English version);

Script language: english;

Mode: Asynchronous.

The main functionality of the configuration is based on "Repositories"
catalog. Each element of the catalog corresponds to a particular
developing repository. For each element of the catalog defined list of
users that have a permission of working with the repository.

The list of tasks that should be automated is defined in the catalog
“Tasks”, its owner is the catalog “Repositories”. Tasks could be run by
several different ways:

-   manually, from 1C:Enterprise client;
-   on the schedule;
-   from command line.

Each task has the list of actions that should be executed. Actions are
running one after one according to serial number of action in the list.

Each action is an element of the catalog “Actions”. An action is
connected to a data processor which could be internal or external, from
AdditionalReportsAndDataProcessors SSL subsystem catalog. Data
processors provide an algorithm that should be executed during task
running.

![alt tag](https://github.com/alexkmbk/1CI/blob/master/Description/TasksDiagram.png)

During task running process, there is a list of common parameters in a
memory which is available for data processors and shared between them.
The list exists only while a task is running. One of the most important
parameters is a path to a dump of a configuration. The path parameter is
being created before making a dump and it guaranties that all data
processors would work with the same path. So, for example, if a task has
two actions: one for making a dump and another one for making a test, you
need to place the dumping action at a first position in an action list
so, for another one there will be available the dump at known path.

An information about running actions and results of their work is being
written in the database by the logging subsystem.

Each action is being written in independent way from the others, so if
the whole process was crashed it is still possible to see on which step
the crash was occurred.

There is a mechanism of notification about task execution results in the
configuration.

The report about successful done or failed task could be sent through
email ot IM to a list of recipients. And it is possible to set two
different list of recipients, the one for successfully executed task and
the other one about failures. Because sometime it is unnecessary to
inform everyone about successful results.

For each action data processor, it could be defined some individual
parameters, which will be saved in the “ActionParams” attribute of the
“Actions” table of the “Task” catalog.

The action parameters editing interface should be provided by a data
processor itself.

Email sending mechanism is provided by “EmailAccounts” subsystem of SSL.

Testing as all others actions could be provided by various additional
special data processors connected to the catalog “Actions”. In the
configuration there are several internal testing data processors:

- data processor for standard module checking (****CheckModules****
command line option ).

- data processor for reposting the list of documents (it is possible to
catch some errors during reposting a document);

- data processor for making list of reports.

# Metadata objects of the configuration (what is already done)

Catalog “Repositories”
======================

Attributes:

Path &lt;String&gt;— the path to the repository ;

WorkingDir &lt;String&gt; - the path to the directory where could be
stored some files needed for working, for example there will be placed
the database, bound to a repository. If it is not defined, it would be
used user's temporary directory.

PlatformPath &lt;String&gt; - the path to the platform executable file.
If it is not defined, it would be used the path given by BinDir()
function.

DBDir &lt;String&gt; - the path to a database which it bound to the
repository. If it is not defined, it would be used the path
“WorkingDir\\DB\\”.

ConfBackupDir &lt;String&gt; - the path where should be stored dumps
from the repository. If it is not defined, it would be used the path
“WorkingDir\\Backup”.

ScheduledJobUser &lt;CatalogRef.Users&gt; - The user from the whom name
will execute scheduled task.

Catalog “Actions”
=================

Attributes:

IsInternal &lt;Boolean&gt; - determines whether the data processor is
internal or not.

InternalDataProcessor &lt;String&gt; - the name of internal data
processor.

DataProcessor &lt;CatalogRef.AdditionalReportsAndDataProcessors&gt; -
the reference to the element of “AdditionalReportsAndDataProcessors”
catalog. It should be set if the data processor is external.

Catalog “Tasks”
===============

Attributes:

ScheduledJobGUID &lt;UUID&gt; - the ID of the scheduled job.

RunBySchedule&lt;Boolean&gt; - determine if the task should be run by
scheduled job.

Tabular sections:

Actions, attributes:

Action &lt;CatalogRef.Actions&gt;.

ActionParams &lt;String&gt; - the string of individual action parameters
of the data processor (in case there are some in a data processor). The
string is generated by function ValueToStringInternal

from structure of parameters.

UUID &lt;UUID&gt; - action parameters identifier.

FailureReportRecipients, attributes:

Email &lt;String&gt;.

SuccessReportRecipients, attributes:

Email &lt;String&gt;.

Document “TaskRunningEvent”
===========================

The document is intended to log task events. Each particular document
represents one task execution.

Attribute:

State &lt;Enum.TaskState&gt;- the state of task execution.

Task &lt;CatalogRef.Tasks&gt; - the reference to executing task.

Repository &lt;CatalogRef.Repositories&gt; - the reference to the
catalog “Repositories”. This attribute is for optimization record level
(RLS) access restriction to “Repositories” catalog related data.

The document doesn’t support posting. At a beginning of task execution,
system creates and writes the document with the state “Started”. During
task execution process, logging information could be stored in the
information register “ActionEventsLog” (would be described further)
where one of the dimension is a reference to TaskRunningEvent document,
but the register and the document are not connected by posting
mechanism.

If all actions were executed, the value of the attribute “State” will be
set as “Success” or “Error” it depends on whether it was successful
execution or not.

Information register “ActionEventsLog”
======================================

The register is intended to log action events. One action during running
can write several events.

Periodicity: No.

Write mode: Independent.

Dimensions:

TaskRunningEvent &lt;DocumentRef.TaskRunningEvent&gt;.

LineNum &lt;Number 9,0&gt; - the serial number of the event, the
numeration is implementing through one task.

Resources:

Action &lt;CatalogRef.Actions&gt; - the source of event.

State &lt;EnumRef.ActionEventTypes&gt; - the type of the event
(Start,Error,DetailedInfo,Success);

Description &lt;String&gt; - text description of the event.

Date &lt;DateTime&gt; - event's date and time.

The register is not periodic because the record will be selected more
often by reference to the TaskRunningEvent document. So, the reference
should be at the first position.

Information register “RepUsers”
===============================

The register is intended to store repository users. For the repository
should be defined at least one user.

Periodicity: Нет.

Write mode: Independent.

Dimensions:

User &lt;CatalogRef.Users&gt; - the reference to the “Users” catalog
from Users subsystem of SSL.

Repository &lt;CatalogRef.Repositories&gt; - the repository.

Resources:

RepUserName &lt;String&gt; - the name of repository user.

RepPassword &lt;String&gt; - the repository password.

Data processor “StartPage”
==========================

The data processor is the desktop for the repository subsystem, it is
intended to provide handy access to repository tasks.

Action data processors
======================

If a data processor is intended to be connected to “Actions” catalog, it
should provide several export functions:

Run(LogLineNumber, CommonParams, Action, ActionParams, ShowMessages),
where

LogLineNumber - serial number of event.

CommonParams - structore with common params that exist while task
running.

Action - reference to the Action catalog element.

ActionParams - params that was set for the action only.

ShowMessages (bool) - determines if it is needed to show interactive
messages .

IsRepositoryDataProcessor() - returns True if it is repository data
processor.

IsParamsForm() -returns True if there available an action parameters
form in the data processor.

At that moment, in the configuration available two internal data
processors:

DumpConfFromRepository — making dump from repository.

SendEmail - sending email message to the list of predefined recipients.
The list of recipients and message template could be defined in a
parameters form provided by the data processor itself. In the text
message template it is possible to set some parameters in square
brackets, they will be replaced by corresponded values from
“CommonParams” structure. For example, the parameter
\[DumpConfFileFullPath\] will be replaced by the path to repository dump
file. The mechanism of message templates is still under developing.

UpdateDB — updating the database in DBDir directory from repository.

CheckModules – Checking modules of the dump by standard platform
command.

Role «RepositoryUser»
======================

Provide access to objects of “Repositories” subsystem. The role has RLS
based mechanism to implement restrictions to “Repositories” catalog and
to other connected tables.

Adopted subsystems from SSL
===========================

-   AdditionalReportsAndDataProcessors
-   BaseFunctionality
-   EmailOperations
-   Users
-   InfobaseVersionUpdate

Run tasks from command line
===========================

In the common module “RepTasks” there is an export function
RunTaskByCode(RepositoryCatalogCode, TaskCatalogCode),

where

RepositoryCatalogCode – code of a repository in numeric format.

TaskCatalogCode – code of a task in numeric format.

The function runs particular task by given codes. It is possible to
execute this function in one or another way. For example it is possible
to set a special parameter in command line of the platform:
run\_RepTasks.RunTaskByCode(&lt;RepositoryCatalogCode&gt;,&lt;TaskCatalogCode&gt;)

Example:

"C:\\Program Files (x86)\\1cv8\\common\\1cestart.exe" Enterprise
/F"D:\\MyDB" /N Administrator /P Password
/C"run\_RepTasks.RunTaskByCode(1,2)"

In this example, a task with code 2 of a repository with code 1 will be
run.

