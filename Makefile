ifeq ($(DSTROOT),)
 $(error DSTROOT must be defined.)
endif
ifeq ($(OBJROOT),)
 $(error OBJROOT must be defined.)
endif
ifeq ($(SYMROOT),)
 $(error SYMROOT must be defined.)
endif

RC_ARCHS ?= i386 x86_64
RC_ProjectName ?= Libcompiler_rt
RC_ProjectSourceVersion ?= 1.0

all : $(SYMROOT)/libcompiler_rt.dylib $(SYMROOT)/libcompiler_rt-dyld.a
INSTALL_TARGET := install-MacOSX

SDKROOT ?= macosx10.13
SDKROOT_EXPANDED = $(shell xcrun --sdk $(SDKROOT) --show-sdk-path)

# Copies any public headers to DSTROOT.
installhdrs:
	@echo No headers to install.

# Copies source code to SRCROOT.
installsrc:
	cp -r . $(SRCROOT)

install:  $(INSTALL_TARGET)

# Copy results to DSTROOT.
install-MacOSX : $(SYMROOT)/libcompiler_rt.dylib \
                 $(SYMROOT)/libcompiler_rt-dyld.a
	mkdir -p $(DSTROOT)/usr/local/lib/dyld
	cp $(SYMROOT)/libcompiler_rt-dyld.a  \
				    $(DSTROOT)/usr/local/lib/dyld/libcompiler_rt.a
	mkdir -p $(DSTROOT)/usr/lib/system
	strip -S $(SYMROOT)/libcompiler_rt.dylib \
	    -o $(DSTROOT)/usr/lib/system/libcompiler_rt.dylib
	cd $(DSTROOT)/usr/lib/system; \
	    ln -s libcompiler_rt.dylib libcompiler_rt_profile.dylib; \
	    ln -s libcompiler_rt.dylib libcompiler_rt_debug.dylib

# Rule to make each dylib slice
$(OBJROOT)/libcompiler_rt-%.dylib : $(OBJROOT)/%/libcompiler_rt.a
	echo "const char vers[] = \"@(#) $(RC_ProjectName)-$(RC_ProjectSourceVersion)\"; " > $(OBJROOT)/version.c
	clang \
	   $(OBJROOT)/version.c -arch $* -dynamiclib \
	   -install_name /usr/lib/system/libcompiler_rt.dylib \
	   -compatibility_version 1 -current_version $(RC_ProjectSourceVersion) \
	   -nodefaultlibs -umbrella System -dead_strip \
	   -L$(SDKROOT_EXPANDED)/usr/lib/system \
	   -Wl,-upward-lunwind \
	   -Wl,-upward-lsystem_m \
	   -Wl,-upward-lsystem_c \
	   -Wl,-upward-lsystem_kernel \
	   -Wl,-upward-lsystem_platform \
	   -Wl,-ldyld \
	   $(DYLIB_FLAGS) -Wl,-force_load,$^ -o $@

# Rule to make fat dylib
$(SYMROOT)/libcompiler_rt.dylib: $(foreach arch,$(filter-out armv4t,$(RC_ARCHS)), \
                                        $(OBJROOT)/libcompiler_rt-$(arch).dylib)
	lipo -create $^ -o  $@
	dsymutil $@

# Rule to make fat archive
$(SYMROOT)/libcompiler_rt-static.a : $(foreach arch,$(RC_ARCHS), \
                         $(OBJROOT)/$(arch)/libcompiler_rt.a)
	lipo -create $^ -o  $@

# rule to make each archive slice for dyld (which removes a few archive members)
$(OBJROOT)/libcompiler_rt-dyld-%.a : $(OBJROOT)/%/libcompiler_rt.a
	cp $^ $@
	DEL_LIST=`$(AR)  -t $@ | egrep 'apple_versioning|gcc_personality_v0|eprintf' | xargs echo` ; \
	if [ -n "$${DEL_LIST}" ] ; \
	then  \
		ar -d $@ $${DEL_LIST}; \
		ranlib $@ ; \
	fi

# rule to make make archive for dyld
$(SYMROOT)/libcompiler_rt-dyld.a : $(foreach arch,$(RC_ARCHS), \
                         $(OBJROOT)/libcompiler_rt-dyld-$(arch).a)
	lipo -create $^ -o  $@

SOURCES += \
	lib/absvdi2.c \
	lib/absvsi2.c \
	lib/absvti2.c \
	lib/addtf3.c \
	lib/addvdi3.c \
	lib/addvsi3.c \
	lib/addvti3.c \
	lib/apple_versioning.c \
	lib/ashldi3.c \
	lib/ashlti3.c \
	lib/ashrdi3.c \
	lib/ashrti3.c \
	lib/atomic.c \
	lib/atomic_flag_clear.c \
	lib/atomic_flag_clear_explicit.c \
	lib/atomic_flag_test_and_set.c \
	lib/atomic_flag_test_and_set_explicit.c \
	lib/atomic_signal_fence.c \
	lib/atomic_thread_fence.c \
	lib/clear_cache.c \
	lib/clzdi2.c \
	lib/clzsi2.c \
	lib/clzti2.c \
	lib/cmpdi2.c \
	lib/cmpti2.c \
	lib/comparetf2.c \
	lib/ctzdi2.c \
	lib/ctzsi2.c \
	lib/ctzti2.c \
	lib/divdc3.c \
	lib/divdi3.c \
	lib/divsc3.c \
	lib/divtf3.c \
	lib/divti3.c \
	lib/divxc3.c \
	lib/enable_execute_stack.c \
	lib/eprintf.c \
	lib/extenddftf2.c \
	lib/extendhfsf2.c \
	lib/extendsftf2.c \
	lib/ffsdi2.c \
	lib/ffsti2.c \
	lib/fixdfdi.c \
	lib/fixdfti.c \
	lib/fixsfdi.c \
	lib/fixsfti.c \
	lib/fixtfdi.c \
	lib/fixtfsi.c \
	lib/fixtfti.c \
	lib/fixunsdfdi.c \
	lib/fixunsdfsi.c \
	lib/fixunsdfti.c \
	lib/fixunssfdi.c \
	lib/fixunssfsi.c \
	lib/fixunssfti.c \
	lib/fixunstfdi.c \
	lib/fixunstfsi.c \
	lib/fixunstfti.c \
	lib/fixunsxfdi.c \
	lib/fixunsxfsi.c \
	lib/fixunsxfti.c \
	lib/fixxfdi.c \
	lib/fixxfti.c \
	lib/floatdidf.c \
	lib/floatdisf.c \
	lib/floatditf.c \
	lib/floatdixf.c \
	lib/floatsitf.c \
	lib/floattidf.c \
	lib/floattisf.c \
	lib/floattitf.c \
	lib/floattixf.c \
	lib/floatundidf.c \
	lib/floatundisf.c \
	lib/floatunditf.c \
	lib/floatundixf.c \
	lib/floatunsitf.c \
	lib/floatuntidf.c \
	lib/floatuntisf.c \
	lib/floatuntitf.c \
	lib/floatuntixf.c \
	lib/gcc_personality_v0.c \
	lib/int_util.c \
	lib/lshrdi3.c \
	lib/lshrti3.c \
	lib/moddi3.c \
	lib/modti3.c \
	lib/muldc3.c \
	lib/muldi3.c \
	lib/mulodi4.c \
	lib/mulosi4.c \
	lib/muloti4.c \
	lib/mulsc3.c \
	lib/multf3.c \
	lib/multi3.c \
	lib/mulvdi3.c \
	lib/mulvsi3.c \
	lib/mulvti3.c \
	lib/mulxc3.c \
	lib/negdi2.c \
	lib/negti2.c \
	lib/negvdi2.c \
	lib/negvsi2.c \
	lib/negvti2.c \
	lib/paritydi2.c \
	lib/paritysi2.c \
	lib/parityti2.c \
	lib/popcountdi2.c \
	lib/popcountsi2.c \
	lib/popcountti2.c \
	lib/powidf2.c \
	lib/powisf2.c \
	lib/powitf2.c \
	lib/powixf2.c \
	lib/subtf3.c \
	lib/subvdi3.c \
	lib/subvsi3.c \
	lib/subvti3.c \
	lib/trampoline_setup.c \
	lib/truncdfhf2.c \
	lib/truncsfhf2.c \
	lib/trunctfdf2.c \
	lib/trunctfsf2.c \
	lib/ucmpdi2.c \
	lib/ucmpti2.c \
	lib/udivdi3.c \
	lib/udivmoddi4.c \
	lib/udivmodti4.c \
	lib/udivti3.c \
	lib/umoddi3.c \
	lib/umodti3.c

SOURCES-EXCLUDE-i386 = \
	lib/absvti2.c \
	lib/addvti3.c \
	lib/ashlti3.c \
	lib/ashrti3.c \
	lib/clzti2.c \
	lib/cmpti2.c \
	lib/ctzti2.c \
	lib/divti3.c \
	lib/ffsti2.c \
	lib/fixdfti.c \
	lib/fixsfti.c \
	lib/fixunsdfti.c \
	lib/fixunssfti.c \
	lib/fixunsxfti.c \
	lib/fixxfti.c \
	lib/floattidf.c \
	lib/floattisf.c \
	lib/floattixf.c \
	lib/floatuntidf.c \
	lib/floatuntisf.c \
	lib/floatuntixf.c \
	lib/lshrti3.c \
	lib/modti3.c \
	lib/muloti4.c \
	lib/multi3.c \
	lib/mulvti3.c \
	lib/negti2.c \
	lib/negvti2.c \
	lib/parityti2.c \
	lib/popcountti2.c \
	lib/subvti3.c \
	lib/ucmpti2.c \
	lib/udivmodti4.c \
	lib/udivti3.c \
	lib/umodti3.c

define ArchTemplate

SOURCES-$(1) = $$(filter-out $$(SOURCES-EXCLUDE-$(1)),$$(SOURCES))
ifeq ($$(SOURCES-$(1)),)
 $$(error No sources for architecture $(1))
endif
OBJECTS-$(1) = $$(foreach file,$$(SOURCES-$(1)),$$(OBJROOT)/$(1)/$$(file).o)

$$(OBJROOT)/$(1)/libcompiler_rt.a : $$(OBJECTS-$(1))
	ar crs $$@ $$^

$$(OBJROOT)/$(1)/%.o : %
	@mkdir -p $$(dir $$@)
	clang -arch $(1) -c -o $$@ $$^ $$(CLANG_FLAGS)

endef

$(eval $(call ArchTemplate,i386))
$(eval $(call ArchTemplate,x86_64))

CLANG_FLAGS = -I$(SRCROOT)/include -I$(SRCROOT)/lib -g
