# Termux2Kali
Convert Termux to kali Linux 


# How run on a Termux?
### update libs
```
pkg update -y && pkg upgrade -y
```

### install kali libs
```
pkg install -y git wget proot-distro
```

### clone project 
```
cd $HOME
git clone https://github.com/mr-r0ot/Termux2Kali.git
```

### Run project 
```
cd Termux2Kali
chmod +x Termux2Kali.sh
bash Termux2Kali.sh
```

