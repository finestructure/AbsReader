#!/bin/sh

sdk="/Xcode4/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS4.2.sdk"
product="build/Release-iphoneos/AbsReader.app"
artwork="Resources/app_icon-512.png"
publishing_target="abslogin:~/public_html/AbsReader/"
manifest="absreader_manifest.plist"
tempdir=.tmp

# build release
xcodebuild -target AbsReader -configuration Release -sdk $sdk

# get version
version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" $product/Info.plist)

echo Version: $version

# make ipa
rm -rf $tempdir
mkdir -p $tempdir/Payload
cp -r "$product" $tempdir/Payload/
chmod -R 775 $tempdir/Payload
cp $artwork $tempdir/iTunesArtwork

base=$(basename "$product" .app)
pushd $tempdir
ipafile="$base"_$version.ipa
zip -r $ipafile Payload iTunesArtwork
popd
cp $tempdir/$ipafile releases/

# update publishing files
sed "s/VERSION/$version/" releases/index.html > $tempdir/index.html
sed "s/IPAFILE/$ipafile/" releases/$manifest > $tempdir/$manifest

# upload file
echo Copying to host...
scp $tempdir/$ipafile $publishing_target
scp $tempdir/index.html $publishing_target
scp $tempdir/$manifest $publishing_target

# clean up
rm -rf $tempdir
