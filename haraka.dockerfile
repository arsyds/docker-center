# Gunakan base image Debian agar support build tools dan Python
FROM node:20-bullseye

# Install dependency untuk build native module (seperti iconv)
RUN apt-get update && apt-get install -y python3 make g++ && rm -rf /var/lib/apt/lists/*

# Install Haraka secara global
RUN npm install -g Haraka

# Inisialisasi Haraka di direktori /haraka
RUN haraka -i /haraka
WORKDIR /haraka

# Tambahkan plugin yang akan digunakan
RUN echo "access\n\
auth/flat_file\n\
rcpt_to.in_host_list\n\
relay\n\
queue/smtp_forward" > config/plugins

# Buat file autentikasi CRAM-MD5 dengan user mailu:mailu
RUN echo "[core]\nmethods=CRAM-MD5\n\n[users]\nmailu=mailu" > config/auth_flat_file.ini

# Tambahkan domain yang valid agar tidak error "No valid MX for your FROM address"
RUN echo "*" > config/host_list

# Konfigurasi smtp_forward agar bisa testing (semua email dikirim ke MailHog atau log)
# Jika kamu ingin forward ke MailHog lokal (port 1025), uncomment baris berikut:
#RUN echo "host=192.168.215.2\nport=1025" > config/smtp_forward.ini
RUN echo "enable_outbound=true\n\
host=mailpit\n\
port=1025\n\
enable_tls=false" > config/smtp_forward.ini

# Default Haraka listen di port 25
EXPOSE 25

# Jalankan Haraka
CMD ["haraka", "-c", "/haraka"]