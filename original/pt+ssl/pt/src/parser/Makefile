# Makefile for PT Scanner Parser pass
# Usage:  make [parser.out]

PASS = parser
SUFFIXES = .ssl .sst .pt .out
.SUFFIXES: ${SUFFIXES}

all:  parser.out

parser.out:  parser.pt scan.sst parser.sst 
	ptc parser.pt


# S/SL make procedure and dependency analysis

.ssl.sst:  
	@touch $*.def
	@mv $*.def $*.def.sav
	@# run the S/SL processor
	ssl $*.ssl
	@# if $*.def exists, the S/SL processor finished successfully
	@if [ -s $*.def ] ; \
	then \
	    exit 0 ; \
	else \
	    mv $*.def.sav $*.def ; \
	    exit 10 ; \
	fi
	@# check for changed definition values
	-@(cat $*.def | sed '/Rule Table Addr/,$$d' > $*.def.new)
	-@(cat $*.def.sav | sed '/Rule Table Addr/,$$d' > $*.def.old)
	-@if (cmp -s $*.def.new $*.def.old) ; \
	then \
	    rm -f $*.def.sav $*.def.new $*.def.old ; \
	else \
	    echo "" ; \
	    echo "WARNING: generated definitions in $*.def have changed!" ; \
	    echo "It may be necessary to hand edit the const definitions in" ; \
	    echo "${PASS}.pt to reflect the changes." ; \
	    echo "" ; \
	    echo "The following definitions have changed ($*.def.diffs):" ; \
	    diff -f $*.def.old $*.def.new > $*.def.diffs ; \
	    cat $*.def.diffs ; \
	    rm -f $*.def.sav $*.def.old $*.def.new ; \
	    echo "" ; \
	    echo "If you want to stop and edit ${PASS}.pt to update these," ; \
	    echo "hit ^C now.  If these differences are irrelevant and you" ; \
	    echo "want to continue making ${PASS}.out, hit return." ; \
	    read x ; \
	fi
