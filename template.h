
template <typename Iterator>
class strided_range
{
	public:

	typedef typename thrust::iterator_difference<Iterator>::type difference_type;

	struct stride_functor : public thrust::unary_function<difference_type,difference_type>
	{
		difference_type stride;

		stride_functor(difference_type stride)
			: stride(stride) {}

		__host__ __device__
		difference_type operator()(const difference_type& i) const
		{
			return stride * i;
		}
	};

	typedef typename thrust::counting_iterator<difference_type>						CountingIterator;
	typedef typename thrust::transform_iterator<stride_functor, CountingIterator>	TransformIterator;
	typedef typename thrust::permutation_iterator<Iterator,TransformIterator>		PermutationIterator;

	// type of the strided_range iterator
	typedef PermutationIterator iterator;

	// construct strided_range for the range [first,last)
	strided_range(Iterator first, Iterator last, difference_type stride)
		: first(first), last(last), stride(stride) {}

	iterator begin(void) const
	{
		return PermutationIterator(first, TransformIterator(CountingIterator(0), stride_functor(stride)));
	}

	iterator end(void) const
	{
		return begin() + ((last - first) + (stride - 1)) / stride;
	}

	protected:
	Iterator first;
	Iterator last;
	difference_type stride;
};


template <typename Iterator>
class repeated_range
{
	public:

	typedef typename thrust::iterator_difference<Iterator>::type difference_type;

	struct repeat_functor : public thrust::unary_function<difference_type,difference_type>
	{
		difference_type repeats;

		repeat_functor(difference_type repeats)
			: repeats(repeats) {}

		__host__ __device__
		difference_type operator()(const difference_type& i) const
		{ 
			return i / repeats;
		}
	};

	typedef typename thrust::counting_iterator<difference_type>					 CountingIterator;
	typedef typename thrust::transform_iterator<repeat_functor, CountingIterator> TransformIterator;
	typedef typename thrust::permutation_iterator<Iterator,TransformIterator>	 PermutationIterator;

	// type of the repeated_range iterator
	typedef PermutationIterator iterator;

	// construct repeated_range for the range [first,last)
	repeated_range(Iterator first, Iterator last, difference_type repeats)
		: first(first), last(last), repeats(repeats) {}
	 
	iterator begin(void) const
	{
		return PermutationIterator(first, TransformIterator(CountingIterator(0), repeat_functor(repeats)));
	}

	iterator end(void) const
	{
		return begin() + repeats * (last - first);
	}
	
	protected:
	Iterator first;
	Iterator last;
	difference_type repeats;
};

template <typename Iterator>
class tiled_range
{
	public:

	typedef typename thrust::iterator_difference<Iterator>::type difference_type;

	struct tile_functor : public thrust::unary_function<difference_type,difference_type>
	{
		difference_type tile_size;

		tile_functor(difference_type tile_size)
			: tile_size(tile_size) {}

		__host__ __device__
		difference_type operator()(const difference_type& i) const
		{ 
			return i % tile_size;
		}
	};

	typedef typename thrust::counting_iterator<difference_type>					 CountingIterator;
	typedef typename thrust::transform_iterator<tile_functor, CountingIterator>	 TransformIterator;
	typedef typename thrust::permutation_iterator<Iterator,TransformIterator>	 PermutationIterator;

	// type of the tiled_range iterator
	typedef PermutationIterator iterator;

	// construct repeated_range for the range [first,last)
	tiled_range(Iterator first, Iterator last, difference_type tiles)
		: first(first), last(last), tiles(tiles) {}
	 
	iterator begin(void) const
	{
		return PermutationIterator(first, TransformIterator(CountingIterator(0), tile_functor(last - first)));
	}

	iterator end(void) const
	{
		return begin() + tiles * (last - first);
	}
	
	protected:
	Iterator first;
	Iterator last;
	difference_type tiles;
};

