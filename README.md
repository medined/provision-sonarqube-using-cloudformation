# Provision SonarQube Using CloudFormation

Provisioning SonarQube typically takes a few manual steps after the software
itself is installed. For example, you need to change the default password and
generate a token.

This project automates everything.

The process shown below uses the internal database so needs to be modified so
large scale use. However, if you just have a few projects, this approach should
be fine.

As always, please adjust the files to your situation.

## Steps in the Process

* Generate random password.
* Save password to Parameter Store.
* Execute the CloudFormation stack.
* Get IP of SonarQube server.
* Wait for server to respond to API request.
* Wait until server is no longer STARTING.
* Verify server is responding with UP.
* Get password from Parameter Store.
* Change the default password.
* Get a sonar token.
* Save token in Parameter Store.

Originally the random password was generated in a different script. The
Parameter Store was used to eliminate having the password appear in the
Git repository.

## Configuration

Edit `sonar.yaml` to set the parameters.

## Execution

```
./start-sonar.sh
```

## Run SonarQube Analysis

Copy `run-sonar-analsys.sh` into your Java project alongside `pom.xml`. Then
run it.

```
./run-sonar-analysis.sh
```
