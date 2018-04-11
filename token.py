import random
import string


def rand(N):
    return ''.join(random.SystemRandom().choice(string.ascii_lowercase + string.digits) for _ in range(N)) #https://stackoverflow.com/a/2257449/1024794


print(rand(6)+"."+rand(16))
