<img src="pages/logo.png" width="360">

# jinks - Application Manager for TEI Publisher

Replaces the custom app generator in earlier versions of TEI Publisher. The idea is to create a more powerful tool for creating, updating and maintaining a custom application. **jinks**

* can not only create new custom applications, but also reconfigure them at a later time
* uses a hierarchy of application *profiles* targeted at specific use cases. A profile can extend or build upon other profiles
* detects local changes to files and leaves them untouched
* comes with its own [templating language](templating.md), which can also process plain-text files (XQuery, CSS etc.)

## Profiles

Profiles are blueprints for applications targeted at a specific use case like a monography, correspondance edition, dictionary etc. Each profile has a subcollection under `profiles` and must contain at least one configuration file, `config.json`, which defines all the variables to be used in templated files.

### `config.json`

The `config.json` must define a property named `id` with a unique, valid URI. This is the URI under which eXist's package manager will later install the application package.

It may also specify a property `extends`, which should contain the name of a profile to extend. TEI Publisher apps will in general extend the *base* profile, which installs the required files shared by all custom TP applications.

The extension process works as follows:

1. jinks creates a merged configuration, assembled from the configurations of all profiles in the extension hierarchy
2. it calls the *write action* on every profile in sequence

### `setup.xql`

The profile may also include an XQuery module called `setup.xql`. If present, jinks will inspect the functions defined in this module, searching for functions with the annotations `%generator:prepare` and `%generator:write`. They represent different stages in the generation process:

* `%generator:prepare`: receives the merged configuration map - including all changes applied by previous calls to prepare - and may return a modified map. Use this to compute and set custom properties needed by your profile.
* `%generator:write`: performs the actual installation.

`%generator:write` receives the merged configuration as parameter `$context`. It should use the functions of the `cpy` module to copy or write files into the target collection, given by the property `$context?target`. The source, i.e. the collection containing the profile's source, is available in `$context?source`.

If no `setup.xql` is present or no `%generator:write` function is defined, the default action is to call

```xquery
cpy:copy-collection($context)
```

which boils down to copying everything contained in the profile's source folder into the target destination.

### Templates

The `cpy:copy-collection` function will automatically process any file containing `.tpl` in its name as a template, which means the contents will be expanded through the [templating module](templating.md) using the current *configuration*.

## Usage

Currently the functionality of jinks is only exposed via the API. Convenient configuration forms will be added later. After installing the jinks application package via the dashboard, open http://localhost:8080/exist/apps/tei-publisher-jinks/api.html in your browser. The `/api/generator/{profile}` provides the main API entry point.

The main entry point into jinks is provided by the module [`modules/generator.xql`](modules/generator.xql), which exposes the function:

```xquery
declare function generator:process($profile as xs:string, $settings as map(*)?, $config as map(*)?)
```

where the parameters are as follows:

* `$profile`: the name of the profile to apply
* `$settings`: general settings to control the generator
* `$config`: user-supplied configuration, which will overwrite the config.json in the profile

The function will return a map with the properties: `conflicts` and `config`, where the first contains a list of resources which were modified by the user since the last run and were therefore not overwritten (see below). `config` shows the merged configuration used during the run.

### Updates and Conflicts

When creating a new custom application, the profile (and its sub-profiles) will copy or write all required files into a temporary collection, package it up as an eXist application xar, and finally install it into eXist.

Once the application has been installed, users may call the manager again with a modified configuration. The manager detects that an app with the same URI does already exist and by default applies the changes to the existing app collection only. The `overwrite` property, which can be passed in the `settings` parameter to `generator:process`, determines how updates are handled:

* *default*: existing files will not be overwritten
* *update*: the target file will be overwritten by the version coming from the profile - unless the user has applied changes (see below)
* *all*: the entire application is rebuilt from the profile and reinstalled into eXist

The application manager will **never** overwrite files which have been changed since they were installed from the profile. To track changes, an SHA-256 key is computed for every file and stored in the `.generator.json` file in the target app.

Conflicting files will be reported by the `generator:process` function.