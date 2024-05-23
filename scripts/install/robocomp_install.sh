set -e
cat /etc/issue || true
branch="${branch:-development}"
source <(curl -sL https://raw.githubusercontent.com/grupo-avispa/robocomp/$branch/scripts/install/resources/robocomp_prerequisites_install.sh)

git clone -b $branch https://github.com/grupo-avispa/robocomp.git
sudo ln -s ~ /home/robocomp
echo "export ROBOCOMP=~/robocomp" >> ~/.bashrc
echo "export PATH=$PATH:/opt/robocomp/bin" >> ~/.bashrc
echo "export PYTHONIOENCODING=utf-8" >> ~/.bashrc
echo "export LD_LIBRARY_PATH=/opt/robocomp/lib:$LD_LIBRARY_PATH" >> ~/.bashrc
export ROBOCOMP=~/robocomp
export PATH=$PATH:/opt/robocomp/bin
export PYTHONIOENCODING=utf-8
sudo [ -d /opt/robocomp ] && sudo rm -r /opt/robocomp
cd robocomp
#sudo pip3 install tools/cli/
#rcconfig init
mkdir build
cd build
cmake -DRCIS=True ..
make -j$(nproc --ignore=2)
sudo env "PATH=$PATH" PYTHONIOENCODING=utf-8 make install
sudo sh -c "echo '/opt/robocomp/lib/' >> /etc/ld.so.conf"
sudo ldconfig
