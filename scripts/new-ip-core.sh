#! /bin/bash

#Exit if any error occurs
set -e

#Credit: https://stackoverflow.com/questions/4774054/reliable-way-for-a-bash-script-to-get-the-full-path-to-itself
SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
TYPE="axils"
NAME="NONAME"
IP_PATH="../axi/axi_lite_slave"
DEST_PATH="$SCRIPT_PATH/../cores"
#DEST_PATH="/home/cospan/sandbox"
SOURCE_PATH="$SCRIPT_PATH/$IP_PATH"



# Get the path to the location
if [ $# -eq 0 ]
  then
    echo "No arguments supplied"
		echo "Please provide a name for your new core"
		echo "e.g. $0 my_core"
		exit
fi
NAME="$1"

shift 1

while getopts o:t: flag
do
    case "${flag}" in
        o) DEST_PATH=${OPTARG};;
				t) TYPE=${OPTARG};;
    esac
done

# Is this is a valid type?
if [ $TYPE != "axils" ]
	then
		echo "Unrecognized type: $TYPE";
		echo "Valid types:"
		echo "	axils (AXI Lite Slave)";
		exit
fi


# Convert type to paths
if [ $TYPE = "axils" ]
	then
		IP_PATH="../axi/axi_lite_slave"
fi

SOURCE_PATH="$SCRIPT_PATH/$IP_PATH"

#Convert all relative elements to absolute
SOURCE_PATH=`cd "$SOURCE_PATH"; pwd`

# Debug Stuff
#echo "Name: $NAME";
#echo "Source Path: $SOURCE_PATH";
#echo "Destination Path: $DEST_PATH";
#echo "Type: $TYPE";
#echo "Script Path: $SCRIPT_PATH";
#echo "IP Path: $IP_PATH";

MODIFY_PATH="$DEST_PATH/$NAME"
#echo "MODIFY Path: $MODIFY_PATH"

echo "Creating Directory: $MODIFY_PATH (if it doesn't already exist)"
mkdir -p $MODIFY_PATH

# Move all the files to the new location
echo "Copy the template project from $SOURCE_PATH to $MODIFY_PATH"
cp -a $SOURCE_PATH/* $MODIFY_PATH

echo "Rename everything in files to the user provided name: $NAME"
grep -riInl 'NAME' $MODIFY_PATH | xargs sed -i "s/NAME/$NAME/g"

echo "Rename the main core file to the user provided name: $NAME.v"
mv $MODIFY_PATH/hdl/NAME.v $MODIFY_PATH/hdl/$NAME.v
mv $MODIFY_PATH/tests/NAME_driver.py $MODIFY_PATH/tests/${NAME}_driver.py



