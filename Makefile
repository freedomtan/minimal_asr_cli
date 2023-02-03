FRAMEWORKS=-framework Speech -framework AVFAudio -framework AppKit
CFLAGS=-O2 ${FRAMEWORKS}

all: test_speech

clean:
	rm -rf test_speech
