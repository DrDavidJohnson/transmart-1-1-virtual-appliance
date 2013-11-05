#!/bin/bash

# This is a helper script to get and build from the fixes_for_Beta_V1Point1 branch of transmartApp in one line
# It is assumed you have Java and Grails setup correctly (take care for Java/Grails versions)

# get and unpack Rmodules from fixes_for_Beta_V1Point1
wget https://github.com/transmart/Rmodules/archive/fixes_for_Beta_V1Point1.zip && unzip fixes_for_Beta_V1Point1.zip && rm fixes_for_Beta_V1Point1.zip && cd Rmodules-fixes_for_Beta_V1Point1 && grails "upgrade --non-interactive" && grails package-plugin && grails maven-install && cd .. && wget https://github.com/transmart/transmartApp/archive/fixes_for_Beta_V1Point1.zip && unzip fixes_for_Beta_V1Point1.zip && rm fixes_for_Beta_V1Point1.zip && cd transmartApp-fixes_for_Beta_V1Point1 && grails "upgrade --non-interactive" && grails "war --non-interactive"
