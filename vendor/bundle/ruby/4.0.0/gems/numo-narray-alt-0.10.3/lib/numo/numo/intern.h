/*
  intern.h
  Ruby/Numo::NArray - Numerical Array class for Ruby
    Copyright (C) 1999-2020 Masahiro TANAKA
*/
#ifndef INTERN_H
#define INTERN_H

#define rb_narray_new nary_new
VALUE nary_new(VALUE elem, int ndim, size_t* shape);
#define rb_narray_view_new nary_view_new
VALUE nary_view_new(VALUE elem, int ndim, size_t* shape);
#define rb_narray_debug_info nary_debug_info
VALUE nary_debug_info(VALUE);

#define na_make_view nary_make_view
VALUE nary_make_view(VALUE self);

#define na_s_allocate nary_s_allocate
VALUE nary_s_allocate(VALUE klass);
#define na_s_allocate_view nary_s_allocate_view
VALUE nary_s_allocate_view(VALUE klass);
#define na_s_new_like nary_s_new_like
VALUE nary_s_new_like(VALUE type, VALUE obj);

void na_alloc_shape(narray_t* na, int ndim);
void na_array_to_internal_shape(VALUE self, VALUE ary, size_t* shape);
void na_index_arg_to_internal_order(int argc, VALUE* argv, VALUE self);
void na_setup_shape(narray_t* na, int ndim, size_t* shape);

#define na_get_elmsz nary_element_stride
// #define na_element_stride nary_element_stride
unsigned int nary_element_stride(VALUE nary);
#define na_dtype_elmsz nary_dtype_element_stride
size_t nary_dtype_element_stride(VALUE klass);

#define na_get_pointer nary_get_pointer
char* nary_get_pointer(VALUE);
#define na_get_pointer_for_write nary_get_pointer_for_write
char* nary_get_pointer_for_write(VALUE);
#define na_get_pointer_for_read nary_get_pointer_for_read
char* nary_get_pointer_for_read(VALUE);
#define na_get_pointer_for_read_write nary_get_pointer_for_read_write
char* nary_get_pointer_for_read_write(VALUE);
#define na_get_offset nary_get_offset
size_t nary_get_offset(VALUE self);

#define na_copy_flags nary_copy_flags
void nary_copy_flags(VALUE src, VALUE dst);

#define na_check_ladder nary_check_ladder
VALUE nary_check_ladder(VALUE self, int start_dim);
#define na_check_contiguous nary_check_contiguous
VALUE nary_check_contiguous(VALUE self);

#define na_flatten_dim nary_flatten_dim
VALUE nary_flatten_dim(VALUE self, int sd);

#define na_flatten nary_flatten
VALUE nary_flatten(VALUE);

#define na_copy nary_dup
VALUE nary_dup(VALUE);

#define na_store nary_store
VALUE nary_store(VALUE self, VALUE src);

#define na_upcast numo_na_upcast
VALUE numo_na_upcast(VALUE type1, VALUE type2);

void na_release_lock(VALUE); // currently do nothing

// used in reduce methods
#define na_reduce_dimension nary_reduce_dimension
VALUE nary_reduce_dimension(
  int argc, VALUE* argv, int naryc, VALUE* naryv, ndfunc_t* ndf, na_iter_func_t nan_iter
);

#define na_reduce_options nary_reduce_options
VALUE nary_reduce_options(VALUE axes, VALUE* opts, int naryc, VALUE* naryv, ndfunc_t* ndf);

// ndloop
VALUE na_ndloop(ndfunc_t* nf, int argc, ...);
VALUE na_ndloop2(ndfunc_t* nf, VALUE args);
VALUE na_ndloop3(ndfunc_t* nf, void* ptr, int argc, ...);
VALUE na_ndloop4(ndfunc_t* nf, void* ptr, VALUE args);

VALUE na_ndloop_cast_narray_to_rarray(ndfunc_t* nf, VALUE nary, VALUE fmt);
VALUE na_ndloop_store_rarray(ndfunc_t* nf, VALUE nary, VALUE rary);
VALUE na_ndloop_store_rarray2(ndfunc_t* nf, VALUE nary, VALUE rary, VALUE opt);
VALUE na_ndloop_inspect(VALUE nary, na_text_func_t func, VALUE opt);
VALUE na_ndloop_with_index(ndfunc_t* nf, int argc, ...);

#define na_info_str nary_info_str
VALUE nary_info_str(VALUE);

#define na_test_reduce nary_test_reduce
bool nary_test_reduce(VALUE reduce, int dim);

void nary_step_array_index(
  VALUE self, size_t ary_size, size_t* plen, ssize_t* pbeg, ssize_t* pstep
);
void nary_step_sequence(VALUE self, size_t* plen, double* pbeg, double* pstep);
void na_parse_enumerator_step(VALUE enum_obj, VALUE* pstep);

// used in aref, aset
#define na_get_result_dimension nary_get_result_dimension
int nary_get_result_dimension(
  VALUE self, int argc, VALUE* argv, ssize_t stride, size_t* pos_idx
);
#define na_aref_main nary_aref_main
VALUE nary_aref_main(int nidx, VALUE* idx, VALUE self, int keep_dim, int nd);

#endif /* ifndef INTERN_H */
