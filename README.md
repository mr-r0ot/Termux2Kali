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

### Run project (Original)
```
cd Termux2Kali
chmod +x Termux2Kali.sh
bash Termux2Kali.sh
```

### Run project (Light)
```
cd Termux2Kali
chmod +x Termux2Kali_light.sh
bash Termux2Kali_light.sh
```


### Original Or Light version?
Original version install kali Linux on termux and install all kali CLI tools,
but Light version install Debian and install all Kali tools

Original version need to more memory and Internet for download 
Original is about 6-7GB but Light is Lesser
