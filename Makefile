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
lib/builtins/absvdi2.c \
lib/builtins/absvsi2.c \
lib/builtins/absvti2.c \
lib/builtins/adddf3.c \
lib/builtins/addsf3.c \
lib/builtins/addtf3.c \
lib/builtins/addvdi3.c \
lib/builtins/addvsi3.c \
lib/builtins/addvti3.c \
lib/builtins/apple_versioning.c \
lib/builtins/ashldi3.c \
lib/builtins/ashlti3.c \
lib/builtins/ashrdi3.c \
lib/builtins/ashrti3.c \
lib/builtins/atomic.c \
lib/builtins/atomic_flag_clear.c \
lib/builtins/atomic_flag_clear_explicit.c \
lib/builtins/atomic_flag_test_and_set.c \
lib/builtins/atomic_flag_test_and_set_explicit.c \
lib/builtins/atomic_signal_fence.c \
lib/builtins/atomic_thread_fence.c \
lib/builtins/bswapdi2.c \
lib/builtins/bswapsi2.c \
lib/builtins/clear_cache.c \
lib/builtins/clzdi2.c \
lib/builtins/clzsi2.c \
lib/builtins/clzti2.c \
lib/builtins/cmpdi2.c \
lib/builtins/cmpti2.c \
lib/builtins/comparedf2.c \
lib/builtins/comparesf2.c \
lib/builtins/comparetf2.c \
lib/builtins/cpu_model.c \
lib/builtins/ctzdi2.c \
lib/builtins/ctzsi2.c \
lib/builtins/ctzti2.c \
lib/builtins/divdc3.c \
lib/builtins/divdf3.c \
lib/builtins/divdi3.c \
lib/builtins/divmoddi4.c \
lib/builtins/divmodsi4.c \
lib/builtins/divsc3.c \
lib/builtins/divsf3.c \
lib/builtins/divsi3.c \
lib/builtins/divtc3.c \
lib/builtins/divtf3.c \
lib/builtins/divti3.c \
lib/builtins/divxc3.c \
lib/builtins/enable_execute_stack.c \
lib/builtins/eprintf.c \
lib/builtins/extenddftf2.c \
lib/builtins/extendhfsf2.c \
lib/builtins/extendsfdf2.c \
lib/builtins/extendsftf2.c \
lib/builtins/ffsdi2.c \
lib/builtins/ffssi2.c \
lib/builtins/ffsti2.c \
lib/builtins/fixdfdi.c \
lib/builtins/fixdfsi.c \
lib/builtins/fixdfti.c \
lib/builtins/fixsfdi.c \
lib/builtins/fixsfsi.c \
lib/builtins/fixsfti.c \
lib/builtins/fixtfdi.c \
lib/builtins/fixtfsi.c \
lib/builtins/fixtfti.c \
lib/builtins/fixunsdfdi.c \
lib/builtins/fixunsdfsi.c \
lib/builtins/fixunsdfti.c \
lib/builtins/fixunssfdi.c \
lib/builtins/fixunssfsi.c \
lib/builtins/fixunssfti.c \
lib/builtins/fixunstfdi.c \
lib/builtins/fixunstfsi.c \
lib/builtins/fixunstfti.c \
lib/builtins/fixunsxfdi.c \
lib/builtins/fixunsxfsi.c \
lib/builtins/fixunsxfti.c \
lib/builtins/fixxfdi.c \
lib/builtins/fixxfti.c \
lib/builtins/floatdidf.c \
lib/builtins/floatdisf.c \
lib/builtins/floatditf.c \
lib/builtins/floatdixf.c \
lib/builtins/floatsidf.c \
lib/builtins/floatsisf.c \
lib/builtins/floatsitf.c \
lib/builtins/floattidf.c \
lib/builtins/floattisf.c \
lib/builtins/floattitf.c \
lib/builtins/floattixf.c \
lib/builtins/floatundidf.c \
lib/builtins/floatundisf.c \
lib/builtins/floatunditf.c \
lib/builtins/floatundixf.c \
lib/builtins/floatunsidf.c \
lib/builtins/floatunsisf.c \
lib/builtins/floatunsitf.c \
lib/builtins/floatuntidf.c \
lib/builtins/floatuntisf.c \
lib/builtins/floatuntitf.c \
lib/builtins/floatuntixf.c \
lib/builtins/gcc_personality_v0.c \
lib/builtins/int_util.c \
lib/builtins/lshrdi3.c \
lib/builtins/lshrti3.c \
lib/builtins/moddi3.c \
lib/builtins/modsi3.c \
lib/builtins/modti3.c \
lib/builtins/muldc3.c \
lib/builtins/muldf3.c \
lib/builtins/muldi3.c \
lib/builtins/mulodi4.c \
lib/builtins/mulosi4.c \
lib/builtins/muloti4.c \
lib/builtins/mulsc3.c \
lib/builtins/mulsf3.c \
lib/builtins/multc3.c \
lib/builtins/multf3.c \
lib/builtins/multi3.c \
lib/builtins/mulvdi3.c \
lib/builtins/mulvsi3.c \
lib/builtins/mulvti3.c \
lib/builtins/mulxc3.c \
lib/builtins/negdf2.c \
lib/builtins/negdi2.c \
lib/builtins/negsf2.c \
lib/builtins/negti2.c \
lib/builtins/negvdi2.c \
lib/builtins/negvsi2.c \
lib/builtins/negvti2.c \
lib/builtins/paritydi2.c \
lib/builtins/paritysi2.c \
lib/builtins/parityti2.c \
lib/builtins/popcountdi2.c \
lib/builtins/popcountsi2.c \
lib/builtins/popcountti2.c \
lib/builtins/powidf2.c \
lib/builtins/powisf2.c \
lib/builtins/powitf2.c \
lib/builtins/powixf2.c \
lib/builtins/subdf3.c \
lib/builtins/subsf3.c \
lib/builtins/subtf3.c \
lib/builtins/subvdi3.c \
lib/builtins/subvsi3.c \
lib/builtins/subvti3.c \
lib/builtins/trampoline_setup.c \
lib/builtins/truncdfhf2.c \
lib/builtins/truncdfsf2.c \
lib/builtins/truncsfhf2.c \
lib/builtins/trunctfdf2.c \
lib/builtins/trunctfsf2.c \
lib/builtins/ucmpdi2.c \
lib/builtins/ucmpti2.c \
lib/builtins/udivdi3.c \
lib/builtins/udivmoddi4.c \
lib/builtins/udivmodsi4.c \
lib/builtins/udivmodti4.c \
lib/builtins/udivsi3.c \
lib/builtins/udivti3.c \
lib/builtins/umoddi3.c \
lib/builtins/umodsi3.c \
lib/builtins/umodti3.c

SOURCES-EXCLUDE-i386 = \
lib/builtins/absvti2.c \
lib/builtins/addvti3.c \
lib/builtins/ashlti3.c \
lib/builtins/ashrti3.c \
lib/builtins/clzti2.c \
lib/builtins/cmpti2.c \
lib/builtins/ctzti2.c \
lib/builtins/divti3.c \
lib/builtins/ffsti2.c \
lib/builtins/fixdfti.c \
lib/builtins/fixsfti.c \
lib/builtins/fixunsdfti.c \
lib/builtins/fixunssfti.c \
lib/builtins/fixunsxfti.c \
lib/builtins/fixxfti.c \
lib/builtins/floattidf.c \
lib/builtins/floattisf.c \
lib/builtins/floattixf.c \
lib/builtins/floatuntidf.c \
lib/builtins/floatuntisf.c \
lib/builtins/floatuntixf.c \
lib/builtins/lshrti3.c \
lib/builtins/modti3.c \
lib/builtins/muloti4.c \
lib/builtins/multi3.c \
lib/builtins/mulvti3.c \
lib/builtins/negti2.c \
lib/builtins/negvti2.c \
lib/builtins/parityti2.c \
lib/builtins/popcountti2.c \
lib/builtins/subvti3.c \
lib/builtins/ucmpti2.c \
lib/builtins/udivmodti4.c \
lib/builtins/udivti3.c \
lib/builtins/umodti3.c

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
