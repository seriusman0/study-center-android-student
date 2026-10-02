import paramiko

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect('100.96.171.43', username='serius', password='kecilsemua')

stdin, stdout, stderr = client.exec_command('cd /var/www/study-center-nias && grep -A 20 "function index(" app/Http/Controllers/Chat/ConversationController.php')
print(stdout.read().decode('utf-8'))

client.close()
