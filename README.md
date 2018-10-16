# Provision SonarQube Using CloudFormation

Provisioning SonarQube typically takes a few manual steps after the software
itself is installed. For example, you need to change the default password and
generate a token.

This project automates everything.

The process shown below uses the internal database so needs to be modified so
large scale use. However, if you just have a few projects, this approach should
be fine.

As always, please adjust the files to your situation.

## Configuration

Edit `sonar.yaml` to set the parameters.

## Execution

```
./start-sonar.sh
```
