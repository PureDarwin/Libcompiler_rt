# -*- mode: makefile-gmake -*-

ModuleName := asan
SubDirs := # none

CCSources := $(foreach file,$(wildcard $(Dir)/*.cc),$(notdir $(file)))
CXXOnlySources := asan_new_delete.cc
COnlySources := $(filter-out $(CXXOnlySources),$(CCSources))
SSources := $(foreach file,$(wildcard $(Dir)/*.S),$(notdir $(file)))
Sources := $(COnlySources) $(SSources)
ObjNames := $(CCSources:%.cc=%.o) $(SSources:%.s=%.o)

Implementation := Generic

Dependencies += $(wildcard $(Dir)/*.h)
Dependencies += $(wildcard $(Dir)/../interception/*.h)
Dependencies += $(wildcard $(Dir)/../sanitizer_common/*.h)
