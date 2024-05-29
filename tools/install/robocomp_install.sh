cat /etc/issue
branch="${branch:-development}"
source <(curl -sL https://raw.githubusercontent.com/grupo-avispa/robocomp/$branch/tools/install/resources/robocomp_prerequisites_install.sh)

git clone -b $branch https://github.com/grupo-avispa/robocomp.git
echo "export ROBOCOMP=$HOME/robocomp" >> $HOME/.bashrc
echo "export PATH=/opt/robocomp/bin:$PATH" >> $HOME/.bashrc
echo "export PYTHONIOENCODING=utf-8" >> $HOME/.bashrc
echo "export LD_LIBRARY_PATH=/opt/robocomp/lib:$LD_LIBRARY_PATH" >> $HOME/.bashrc
export ROBOCOMP=$HOME/robocomp
export PATH=$PATH:/opt/robocomp/bin
export PYTHONIOENCODING=utf-8
sudo ln -s ${HOME} /home/robocomp
sudo [ -d /opt/robocomp ] && sudo rm -r /opt/robocomp
cd robocomp
sudo pip3 install tools/cli/
rcconfig init
mkdir build
cd build
cmake -DRCIS=True ..
make -j$(nproc --ignore=2)
sudo env "PATH=$PATH" PYTHONIOENCODING=utf-8 make install
sudo sh -c "echo '/opt/robocomp/lib/' >> /etc/ld.so.conf"
sudo ldconfig
