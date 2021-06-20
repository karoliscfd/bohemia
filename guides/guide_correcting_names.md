# Correcting names

## Context

- The Bohemia project collects name data from study participants (ie, "John Doe").  
- Sites store name data, but the project/sponsor (ISGlobal) and contractors (Databrew) do _not_ have access to name data.  
- In order to prevent access, name data is stored in an encrypted format; the sites have the decryption key.  
- Occasionally, a site needs Databrew to implement a modification to name data, due to human error in data entry.  
- In order to implement such a modification, the sites must supply instructions to Databrew with names _already encrypted_.  
- This guide gives an example of how to encrypt names so as to provide correction instrutions to Databrew.  

## Example instructions

Let's take a fictional household, `ABC-123`, with a fictional person, `John Doe`, who has a fictional person ID, `ABC-123-001`. The site data manager becomes aware that `John Doe` is actually named `John Boe` and that his ID number is actually `ABC-123-002`.

In order to pass this information to Databrew so that Databrew can implement the change in the study database and data cleaning scripts, the sites should:
- Send the `instanceID` associated with the individual.  
- Send the `household ID` and `person ID` associated with the individual.  
- **NOT** send the name associated with the individual.

Since the name cannot be sent, but the site requires a correction to the name, the site should send instructions along with the _encrypted, corrected name_. In other words...

**Incorrect way**

```
Please change the name of the person associated with instanceID uuid:131udsaf98r13 to "John Boe"
```

**Correct way**

```
Please change the name of the person associated with instanceID uuid:131udsaf98r13 to "5f c7 fe 7b 4c 89 76 46 fd a0 5e e0 d4 2d 9c 19 88 73 65 36 c5 20 be 2f ec ff 5c 34 d6 be 4b 1c 09 02 cd 7a 3a 39 6e cd eb b5 00 54 bf 9c 04 e3 9b 53 1b 8d 1d fa 32 26 fa 9a de de 29 07 44 45 da 01 c7 dd 2d ac c9 8f 4a 61 96 96 52 8d ab 8f d3 b9 a0 b2 ff 86 ef 27 1d 19 e3 65 47 78 7b 99 77 68 ff 14 9a d2 0d 13 0a 34 52 62 14 64 35 65 24 38 7f 5e d0 f6 5d f6 d0 30 b9 17 f7 94 62 38 fc 51 38 86 3f b0 f0 09 02 2e d4 88 cf 8e 46 7d 68 5e 70 e3 84 17 eb 79 1f ed 19 22 48 ca 8e 6e 3b 8f e4 3a 62 c1 ce ea ec c6 14 aa cf 6c 49 03 86 94 ee 3f ab 88 54 37 89 b5 2e ee 72 a8 9b c8 49 f9 4d c4 8b 1a 2d f2 9b 06 5e 9a 64 99 4f 3f 74 bc cf 91 98 43 50 c0 0e 03 eb 2a 03 99 44 ba e6 01 45 c9 79 e3 1d bf 8b 07 62 a2 3a d1 c1 9c 8e 1f 4e f0 95 05 dd 19 58 7e 0d 6a 02 07 c5 07"
```

## Encrypting a name

In order to encrypt a name, one can run code in R as follows (ensure correct paths, and update name):

```
# Load the bohemia package
library(bohemia)
# Define the location of the public encryption key
kf <- '../credentials/bohemia_pub.pem'
# Encrypt the name
encrypted_name <- encrypt_private_data(data = 'John Boe',
                     keyfile = kf)
# Print the encrypted name
encrypted_name
```
