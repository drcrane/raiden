#!/bin/sh
if [ "X${USER}" == 'Xroot' ] ; then
export PS1="\[\e[1;31m\]\h \[\e[1;34m\]\w \[\$([ \$? != 0 ] && echo -e '\e[31m')\]\\$\[\e[0m\] "
else
export PS1="\[\e[1;32m\]\u@\h \[\e[1;34m\]\w \[\$([ \$? != 0 ] && echo -e '\e[31m')\]\\$\[\e[0m\] "
fi
