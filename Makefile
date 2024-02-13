LIBSRC=0D/odin/std
ODIN_FLAGS ?= -debug -o:none
D2J=0d/das2json/das2json

dev:
	@echo needs upgrade to no-name inputs

run: ptpascal0d transpile.drawio.json
	./ptpascal0d test.p main ptpascal0d.drawio $(LIBSRC)/transpile.drawio

ptpascal0d: ptpascal0d.drawio.json
	odin build . $(ODIN_FLAGS)

ptpascal0d.drawio.json: ptpascal0d.drawio transpile.drawio.json
	$(D2J) ptpascal0d.drawio

transpile.drawio.json: $(LIBSRC)/transpile.drawio
	$(D2J) $(LIBSRC)/transpile.drawio

clean:
	rm -rf ptpascal0d ptpascal0d.dSYM
