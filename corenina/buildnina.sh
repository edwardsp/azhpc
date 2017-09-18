#!/bin/bash
dotnet build -c release
dotnet publish -c release -o ./bin
