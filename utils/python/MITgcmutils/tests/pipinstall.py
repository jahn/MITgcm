#!/usr/bin/env python
# install packages one by one so we can work around missing dependency declarations
import sys
from subprocess import call

args = sys.argv[1:]

idash = args.index('--')
opts = args[:idash]
args = args[idash+1:]

packages = []
while args:
    arg = args.pop(0)
    myargs = [arg]
    while arg[0] == '-':
        arg = args.pop(0)
        myargs.append(arg)

    if args and args[0] in ['<', '=', '>', '<=', '==', '>=']:
        myargs[-1] += args.pop(0)
        myargs[-1] += args.pop(0)

    packages.append(myargs)

for args in packages:
    call(['pip', 'install'] + opts + args)

