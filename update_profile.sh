#!/bin/sh

publishing_target="abslogin:~/public_html/AbsReader/"
profile=releases/iOS_Team_Provisioning_Profile_.mobileprovision

scp $profile $publishing_target
