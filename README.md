# Selenoid Setup
This repo's intent is to be able to provide simpler ways to setup selenoid based grid. Please see [selenoid](https://aerokube.com/selenoid-ui/latest/) for additional details about selenoid.

> This is verified to work on Ubuntu machines. It should work just fine on other linux flavours. Please open issues if it does not!

## Getting started

```
sudo /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/segrid/selenoid-setup/main/install.sh)"
```

## Usage
Towards the end of installation, install script will print actuals URL for both selenoid UI and selenium webdriver.

Selenoid UI:
> http://\<private-ip\>:8080/

URL for Selenium Remote WebDriver:
> http://\<private-ip\>:4444/wd/hub