#!/bin/sh

publishing_target="abslogin:~/public_html/AbsReader/"
profile=Team_Provisioning_Profile_.mobileprovision

scp $profile $publishing_target
