# Request admin privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {   
    $arguments = "& '" + $myinvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    Break
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Show-InputDialog {
    param([string]$title, [string]$prompt, [string]$default)
    
    $inputForm = New-Object System.Windows.Forms.Form
    $inputForm.Text = $title
    $inputForm.Size = New-Object System.Drawing.Size(400,200)
    $inputForm.StartPosition = 'CenterScreen'
    $inputForm.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#121212")
    $inputForm.ForeColor = [System.Drawing.Color]::White

    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(10,20)
    $label.Size = New-Object System.Drawing.Size(360,20)
    $label.Text = $prompt
    $label.ForeColor = [System.Drawing.Color]::White
    $inputForm.Controls.Add($label)

    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Location = New-Object System.Drawing.Point(10,50)
    $textBox.Size = New-Object System.Drawing.Size(360,20)
    $textBox.Text = $default
    $textBox.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1E1E1E")
    $textBox.ForeColor = [System.Drawing.Color]::White
    $inputForm.Controls.Add($textBox)

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Location = New-Object System.Drawing.Point(75,100)
    $okButton.Size = New-Object System.Drawing.Size(100,30)
    $okButton.Text = 'OK'
    $okButton.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#BB86FC")
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $inputForm.Controls.Add($okButton)

    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Location = New-Object System.Drawing.Point(225,100)
    $cancelButton.Size = New-Object System.Drawing.Size(100,30)
    $cancelButton.Text = 'Отмена'
    $cancelButton.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#CF6679")
    $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $inputForm.Controls.Add($cancelButton)

    $inputForm.AcceptButton = $okButton
    $inputForm.CancelButton = $cancelButton

    $result = $inputForm.ShowDialog()
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        return $textBox.Text
    }
    return $null
}

# Create main form
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Настройка сетевых параметров Windows'
$form.Size = New-Object System.Drawing.Size(600,600)
$form.StartPosition = 'CenterScreen'
$form.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#121212")
$form.ForeColor = [System.Drawing.Color]::White

# Style for buttons
$buttonStyle = @{
    BackColor = [System.Drawing.ColorTranslator]::FromHtml("#BB86FC")
    ForeColor = [System.Drawing.Color]::Black
    FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    Width = 250
    Height = 40
    Font = New-Object System.Drawing.Font("Segoe UI", 10)
}

# Create buttons
$y = 20
$buttons = @(
    "Показать текущие настройки",
    "Изменить имя рабочей группы",
    "Настроить SMB 2.0",
    "Настроить обнаружение сети",
    "Настроить общий доступ к файлам",
    "Управление анонимным доступом",
    "Восстановить настройки по умолчанию"
)

$outputBox = New-Object System.Windows.Forms.TextBox
$outputBox.Location = New-Object System.Drawing.Point(20, 320)
$outputBox.Size = New-Object System.Drawing.Size(540, 120)
$outputBox.Multiline = $true
$outputBox.ReadOnly = $true
$outputBox.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1E1E1E")
$outputBox.ForeColor = [System.Drawing.Color]::White
$form.Controls.Add($outputBox)

foreach ($buttonText in $buttons) {
    $button = New-Object System.Windows.Forms.Button
    $button.Location = New-Object System.Drawing.Point(20,$y)
    $button.Text = $buttonText
    foreach ($key in $buttonStyle.Keys) {
        $button.$key = $buttonStyle[$key]
    }
    
    $button.Add_Click({
        switch ($this.Text) {
            "Показать текущие настройки" {
                $workgroup = (Get-WmiObject -Class Win32_ComputerSystem).Workgroup
                $smb = (Get-SmbServerConfiguration).EnableSMB2Protocol
                $discovery = (Get-NetFirewallRule -DisplayGroup 'Network Discovery').Enabled
                $outputBox.Text = "Рабочая группа: $workgroup`r`nSMB 2.0: $smb`r`nОбнаружение сети: $discovery"
            }
            "Изменить имя рабочей группы" {
                $newWorkgroup = Show-InputDialog "Изменение рабочей группы" "Введите имя рабочей группы:" "WORKGROUP"
                if ($newWorkgroup) {
                    Add-Computer -WorkgroupName $newWorkgroup -Force
                    $outputBox.Text = "Рабочая группа изменена на: $newWorkgroup"
                }
            }
            "Настроить SMB 2.0" {
                $result = [System.Windows.Forms.MessageBox]::Show("Включить SMB 2.0?", "SMB 2.0", [System.Windows.Forms.MessageBoxButtons]::YesNo)
                if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
                    Set-SmbServerConfiguration -EnableSMB2Protocol $true -Force
                    $outputBox.Text = "SMB 2.0 включен"
                } else {
                    Set-SmbServerConfiguration -EnableSMB2Protocol $false -Force
                    $outputBox.Text = "SMB 2.0 выключен"
                }
            }
            "Настроить обнаружение сети" {
                $result = [System.Windows.Forms.MessageBox]::Show("Включить обнаружение сети?", "Обнаружение сети", [System.Windows.Forms.MessageBoxButtons]::YesNo)
                if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
                    Set-NetFirewallRule -DisplayGroup "Network Discovery" -Enabled True
                    $outputBox.Text = "Обнаружение сети включено"
                } else {
                    Set-NetFirewallRule -DisplayGroup "Network Discovery" -Enabled False
                    $outputBox.Text = "Обнаружение сети выключено"
                }
            }
            "Настроить общий доступ к файлам" {
                netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes
                $outputBox.Text = "Общий доступ к файлам включен"
            }
            "Управление анонимным доступом" {
                $result = [System.Windows.Forms.MessageBox]::Show("Включить анонимный доступ?", "Анонимный доступ", [System.Windows.Forms.MessageBoxButtons]::YesNo)
                if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
                    Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\LanmanServer\Parameters" -Name "RestrictNullSessAccess" -Value 0
                    $outputBox.Text = "Анонимный доступ включен"
                } else {
                    Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\LanmanServer\Parameters" -Name "RestrictNullSessAccess" -Value 1
                    $outputBox.Text = "Анонимный доступ выключен"
                }
            }
            "Восстановить настройки по умолчанию" {
                Set-SmbServerConfiguration -EnableSMB2Protocol $true -Force
                Set-NetFirewallRule -DisplayGroup "Network Discovery" -Enabled True
                netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes
                Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\LanmanServer\Parameters" -Name "RestrictNullSessAccess" -Value 1
                $outputBox.Text = "Настройки восстановлены по умолчанию"
            }
        }
    })
    
    $form.Controls.Add($button)
    $y += 45
}

# Add status bar
$statusBar = New-Object System.Windows.Forms.StatusStrip
$statusBar.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1E1E1E")
$statusBarLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
$statusBarLabel.ForeColor = [System.Drawing.Color]::White
$statusBar.Items.Add($statusBarLabel)
$form.Controls.Add($statusBar)

# Add exit button
$exitButton = New-Object System.Windows.Forms.Button
$exitButton.Location = New-Object System.Drawing.Point(20, 450)
$exitButton.Text = "Выход"
foreach ($key in $buttonStyle.Keys) {
    $exitButton.$key = $buttonStyle[$key]
}
$exitButton.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#CF6679")
$exitButton.Add_Click({ $form.Close() })
$form.Controls.Add($exitButton)

# Add hover effects
$form.Controls | Where-Object {$_ -is [System.Windows.Forms.Button]} | ForEach-Object {
    $defaultColor = $_.BackColor
    $_.Add_MouseEnter({
        $this.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#03DAC6")
    })
    $_.Add_MouseLeave({
        $this.BackColor = $defaultColor
    })
}

# Update status bar on actions
$form.Controls | Where-Object {$_ -is [System.Windows.Forms.Button]} | ForEach-Object {
    $_.Add_Click({
        $statusBarLabel.Text = "Выполнено: $($this.Text)"
    })
}

# Make form resizable
$form.Add_Resize({
    $outputBox.Width = $form.ClientSize.Width - 40
    $form.Controls | Where-Object {$_ -is [System.Windows.Forms.Button]} | ForEach-Object {
        $_.Width = $form.ClientSize.Width - 40
    }
})

# Show form
[void]$form.ShowDialog()
