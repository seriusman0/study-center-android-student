import paramiko
import json
import time
import requests

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect('100.96.171.43', username='serius', password='kecilsemua')

php_script = """
<?php
require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$kernel = $app->make(Illuminate\\Contracts\\Console\\Kernel::class);
$kernel->bootstrap();

$user1 = App\\Models\\User::where('email', 'like', '%testuser%')->orWhere('username', 'like', '%testuser%')->first();
$user2 = App\\Models\\User::where('id', '!=', $user1->id)->first();

if (!$user1 || !$user2) {
    echo json_encode(["error" => "Users not found"]);
    exit;
}

$conv = App\\Models\\Conversation::where('type', 'private')
    ->whereHas('participants', function($q) use ($user1) { $q->where('user_id', $user1->id); })
    ->whereHas('participants', function($q) use ($user2) { $q->where('user_id', $user2->id); })
    ->first();

if (!$conv) {
    $conv = App\\Models\\Conversation::create([
        'type' => 'private',
        'created_by' => $user1->id
    ]);
    $conv->participants()->attach([
        $user1->id => ['role' => 'member'],
        $user2->id => ['role' => 'member']
    ]);
}

$token = $user1->createToken('android-test')->plainTextToken;

$res = [
    'conv_id' => $conv->id,
    'user1_id' => $user1->id,
    'user2_id' => $user2->id,
    'token' => explode('|', $token)[1] ?? $token,
    'full_token' => $token
];
file_put_contents('test_setup.json', json_encode($res));
echo "OK";
"""

sftp = client.open_sftp()
with sftp.file('/var/www/study-center-nias/setup_chat_test.php', 'w') as f:
    f.write(php_script)
sftp.close()

stdin, stdout, stderr = client.exec_command("docker exec -i study-center-nias-php-1 php setup_chat_test.php")
out = stdout.read().decode('utf-8')
err = stderr.read().decode('utf-8')

if "OK" in out:
    sftp = client.open_sftp()
    with sftp.file('/var/www/study-center-nias/test_setup.json', 'r') as f:
        data = json.load(f)
        
    print("Conversation ID:", data['conv_id'])
    
    # 1. Android -> Web
    print("Testing Android -> Web...")
    url = f"https://studycenter.nanoprojectdevindonesia.com/api/chat/conversations/{data['conv_id']}/messages"
    headers = {
        "Authorization": f"Bearer {data['full_token']}",
        "Accept": "application/json"
    }
    payload = {
        "type": "text",
        "body": "Hello from Android (test script)!"
    }
    r = requests.post(url, headers=headers, json=payload)
    print("Android -> Web Response:", r.status_code, r.text)

    # 2. Web -> Android
    print("Testing Web -> Android...")
    php_reply = f"""
    <?php
    require __DIR__.'/vendor/autoload.php';
    $app = require_once __DIR__.'/bootstrap/app.php';
    $kernel = $app->make(Illuminate\\Contracts\\Console\\Kernel::class);
    $kernel->bootstrap();

    $conv = App\\Models\\Conversation::find({data['conv_id']});
    $msg = App\\Models\\Message::create([
        'conversation_id' => $conv->id,
        'user_id' => {data['user2_id']},
        'type' => 'text',
        'body' => 'Hello back from Web (Tinker)!'
    ]);
    event(new App\\Events\\MessageSent($msg));
    echo "Web reply sent! Msg ID: " . $msg->id;
    """
    with sftp.file('/var/www/study-center-nias/reply_chat_test.php', 'w') as f2:
        f2.write(php_reply)
    
    stdin2, stdout2, stderr2 = client.exec_command("docker exec -i study-center-nias-php-1 php reply_chat_test.php")
    print("Web -> Android Response:", stdout2.read().decode('utf-8').strip())
else:
    print("Setup failed:", out, err)

client.exec_command("rm -f /var/www/study-center-nias/setup_chat_test.php /var/www/study-center-nias/reply_chat_test.php /var/www/study-center-nias/test_setup.json")
client.close()
