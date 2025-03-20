#!/bin/bash
set -x -e

export PATH=$PATH:/usr/local/bin

HAIL_ARTIFACT_DIR="/opt/hail"
HAIL_PROFILE="/etc/profile.d/hail.sh"
JAR_HAIL="hail-all-spark.jar"
ZIP_HAIL="hail-python.zip"

REPOSITORY_URL="https://github.com/hail-is/hail.git"


function install_prereqs {
	mkdir -p "$HAIL_ARTIFACT_DIR"

	dnf -y install java-11-amazon-corretto-headless java-11-amazon-corretto-devel gcc-c++ \
        cmake \
        git \
        lz4 \
        lz4-devel \
        blas

    #curl -LsSf https://astral.sh/uv/install.sh | sh
    python3 -m ensurepip --upgrade

    python3 -m venv tutorial-env
    source tutorial-env/bin/activate

	WHEELS="uv
    pyspark==3.5.3
	build"

	for WHEEL_NAME in $WHEELS
	do
		python3 -m pip install "$WHEEL_NAME"
	done

    # hail try to reinstall the pip
    #dnf -y remove python3-pip
}

function hail_build
{
	echo "Building Hail v.$HAIL_VERSION from source with Spark v.$SPARK_VERSION"

	export JAVA_HOME=/usr/lib/jvm/java-11-amazon-corretto

	export PATH=$PATH:$HOME/.local/bin

    if [ -d "./hail"  ]; then
        rm -rf ./hail
	    git clone "$REPOSITORY_URL"
	    #git checkout "$HAIL_VERSION"
    else
	    git clone "$REPOSITORY_URL"
	    #git checkout "$HAIL_VERSION"
    fi
	cd hail/hail
	make install-on-cluster HAIL_COMPILE_NATIVES=1 SCALA_VERSION=$SCALA_VERSION SPARK_VERSION=$SPARK_VERSION
}

function hail_install
{
	echo "Installing Hail locally"

	cat <<- HAIL_PROFILE > "$HAIL_PROFILE"
	export SPARK_HOME="/usr/lib/spark"
	export PYSPARK_PYTHON="python3"
	export PYSPARK_SUBMIT_ARGS="--conf spark.kryo.registrator=is.hail.kryo.HailKryoRegistrator --conf spark.serializer=org.apache.spark.serializer.KryoSerializer pyspark-shell"
	export PYTHONPATH="$HAIL_ARTIFACT_DIR/$ZIP_HAIL:\$SPARK_HOME/python:\$SPARK_HOME/python/lib/py4j-src.zip:\$PYTHONPATH"
	HAIL_PROFILE

	#cp "$PWD/build/libs/$JAR_HAIL" "$HAIL_ARTIFACT_DIR"
	cp "$PWD/build/deploy/build/lib/hail/backend/$JAR_HAIL" "$HAIL_ARTIFACT_DIR"

}

function cleanup()
{
  rm -rf /root/.gradle
  rm -rf /home/ec2-user/hail
  rm -rf /root/hail
}

install_prereqs
hail_build
hail_install
cleanup
