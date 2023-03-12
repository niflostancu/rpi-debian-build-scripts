#!/bin/bash
# Configure services (ssh, mostly)

# create user, if it doesn't exist
getent passwd "$MAIN_USER" &> /dev/null || {
    useradd -m -s /bin/bash "$MAIN_USER"
    passwd -d "$MAIN_USER"
}
# give sudo rights
grep -q "$MAIN_USER" /etc/sudoers 2>/dev/null || \
    (echo "$MAIN_USER ALL=(ALL:ALL) ALL" | EDITOR='tee -a' visudo)

# copy authorized_keys for the main user (if exists)
if [[ -f "$DIST_DIR/authorized_keys" ]]; then
    install -o"$MAIN_USER" -m700 -d "/home/$MAIN_USER/.ssh"
    install -o"$MAIN_USER" -m600 -D "$DIST_DIR/authorized_keys" "/home/$MAIN_USER/.ssh/authorized_keys"
fi

