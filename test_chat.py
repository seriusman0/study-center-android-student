import paramiko
import sys

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect('100.96.171.43', username='serius', password='kecilsemua')

tinker_command = """
$user = App\\Models\\User::first();
$conv = App\\Models\\Conversation::first();
if ($conv && $user) {
    $msg = App\\Models\\Message::create([
        'conversation_id' => $conv->id,
        'user_id' => $user->id,
        'type' => 'text',
        'body' => 'Test message from Web Tinker!',
    ]);
    event(new App\\Events\\MessageSent($msg));
    echo "Sent message id: " . $msg->id;
} else {
    echo "No user or conv found";
}
"""

stdin, stdout, stderr = client.exec_command(f'cd /var/www/study-center-nias && php artisan tinker --execute="{tinker_command}"')
print(stdout.read().decode('utf-8'))
print(stderr.read().decode('utf-8'))

client.close()
