**Run this before add logic to server block**


Run **chmod +x nginx-config.sh**
Run **./nginx-config.sh**


**add inside server blocks**

server {
    ....

    **if ($badagent) {
        return 403;
    }

    if ($badreferrer) {
        return 403;
    }**


    ....
}

**Reload nginx**
