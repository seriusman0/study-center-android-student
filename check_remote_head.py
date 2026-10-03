import paramiko

def run_ssh_command(host, username, password, command):
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    try:
        client.connect(host, username=username, password=password)
        stdin, stdout, stderr = client.exec_command(command)
        output = stdout.read().decode('utf-8', errors='replace')
        error = stderr.read().decode('utf-8', errors='replace')
        return output if output else error
    finally:
        client.close()

if __name__ == "__main__":
    host = '100.96.171.43'
    user = 'serius'
    pw = 'kecilsemua'
    
    cmd = "cd /var/www/study-center-nias && head -n 50 routes/web.php"
    res = run_ssh_command(host, user, pw, cmd)
    with open("remote_routes_head.txt", "w", encoding="utf-8") as f:
        f.write(res)
