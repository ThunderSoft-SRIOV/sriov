# Secure Boot

For more information, please refer to [SecureBoot](https://wiki.debian.org/SecureBoot).

1. Create a custom MOK
    ```sh
    mkdir -p /var/lib/shim-signed/mok/

    cd /var/lib/shim-signed/mok/

    openssl req -nodes -new -x509 -newkey rsa:2048 -keyout MOK.priv -outform DER -out MOK.der -days 36500 -subj "/CN=My Name/"

    openssl x509 -inform der -in MOK.der -out MOK.pem
    ```

2. Enrolling your key
    ```sh
    sudo mokutil --import /var/lib/shim-signed/mok/MOK.der
    ```

3. Sign kernel

    *Note: First, install [sbsigntool](https://packages.debian.org/search?keywords=sbsigntool)

    ```sh
    sbsign --key MOK.priv --cert MOK.pem "/boot/vmlinuz-$VERSION" --output "/boot/vmlinuz-$VERSION.tmp"

    sudo mv "/boot/vmlinuz-$VERSION.tmp" "/boot/vmlinuz-$VERSION"
    ```
