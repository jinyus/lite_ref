#!/bin/bash

# The first argument is the action (test or publish)
ACTION=$1
# The second argument is the target (core, flutter, or example)
TARGET=$2

CURRENT_DIR=$(pwd)

test_target() {
    cd $CURRENT_DIR # for "all" tests, we need to be in the root directory

    if [ "$1" == "core" ]; then
        echo "testing core"
        cd packages/lite_ref_core &&
            flutter test --coverage --timeout 5s
    elif [ "$1" == "flutter" ]; then
        echo "testing flutter"
        cd packages/lite_ref &&
            flutter test --coverage --timeout 5s
    elif [ "$1" == "all" ]; then
        test_target "core" &&
            test_target "flutter"
    else
        echo -e "unknown test \"$1\" \nValid tests are: core, all"
    fi
}

publish_target() {
    cp README.md packages/lite_ref/README.md &&
        if [ "$1" == "core" ]; then
            echo "publishing core"
            cd packages/lite_ref_core &&
                dart pub publish
        elif [ "$1" == "flutter" ]; then
            echo "publishing flutter"
            cd packages/lite_ref &&
                dart pub publish
        else
            echo -e "unknown package \"$1\" \nValid packages are: core, flutter, lint"
        fi
}

deps() {
    cd $CURRENT_DIR/packages/lite_ref &&
        flutter pub get &&
        cd $CURRENT_DIR/packages/lite_ref_beacon &&
        flutter pub get &&
        cd $CURRENT_DIR/examples/counter &&
        flutter pub get &&
        cd $CURRENT_DIR/examples/flutter_example &&
        flutter pub get

}

if [ "$ACTION" == "test" ]; then
    test_target $TARGET
elif [ "$ACTION" == "pub" ]; then
    publish_target $TARGET
elif [ "$ACTION" == "deps" ]; then
    deps
else
    echo -e "Unknown action \"$ACTION\" \nValid actions are: test, publish"
fi
