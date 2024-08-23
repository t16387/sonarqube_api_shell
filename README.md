# Project Title

Integrate sonarqube offical api(9.9 LTA version) by shell script.

## Description

It is a shell script that run in macos and linux.

All process will not send data to any place but your own sonarqube server.

Due to company network issue, my concern is to install as less package as I could.(Now should be no need to install any package)

It allow both username password and token for the program.

## Getting Started

### Executing program

* How to run the program

First start, create a credential file on current script directory.Enter your sonarqube server info and credential.
```
sh sonar_api_integration.sh -c
```

For edit / resetcredential, please edit credential file manually.Or remove it by this command, then run again
```
sh sonar_api_integration.sh -r
```

Display project information
```
sh sonar_api_integration.sh -d
```

Display project information by name
```
sh sonar_api_integration.sh -sn project_name
```

Display project information by key
```
sh sonar_api_integration.sh -sk project_key
```

Add tag to specific project
```
sh sonar_api_integration.sh -t
```

Add muti tags to specific project
```
sh sonar_api_integration.sh -st
```

Display current version of Sonarqube
```
sh sonar_api_integration.sh -v
```

## Help

Display a list of options
```
sh sonar_api_integration.sh -h
```

## Authors

Contributors names and contact info

ex. Nick Ho  
ex. [@Nick Ho](t16387@hotmail.com)

## Version History

* 0.1
    * Initial Release

## License

This project is licensed under the License - see the LICENSE.md file for details

## Acknowledgments

Inspiration, code snippets, etc.
* [readme template](https://gist.github.com/DomPizzie/7a5ff55ffa9081f2de27c315f5018afc)
* [Sonarqube api doc](https://docs.sonarsource.com/sonarqube/9.9/extension-guide/web-api/)
