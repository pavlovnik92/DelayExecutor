//
//  DelayExecutor.m
//  DelayExecutor
//
//  Created by Nikita Pavlov on 03.10.2020.
//

#define weakify(var) __weak typeof(var) AHKWeak_##var = var;

#define strongify(var) \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Wshadow\"") \
__strong typeof(var) var = AHKWeak_##var; \
_Pragma("clang diagnostic pop")


#import "DelayExecutor.h"

static const uint64_t DelayedExecutorLeeway = 0.1 * NSEC_PER_SEC;


@interface DelayExecutor ()

@property (nonatomic, assign) NSTimeInterval coalescingPeriod;

@property (atomic, copy) dispatch_block_t actualBlock;

@property (nonatomic, strong) dispatch_source_t timer;
@property (nonatomic, assign) BOOL resumed;
@property (nonatomic, strong) NSObject *timerLock;

@end


@implementation DelayExecutor

- (void)dealloc
{
	[self cancelTimer];
}

- (instancetype)initWithCoalescingPeriod:(NSTimeInterval)coalescingPeriod queue:(nonnull dispatch_queue_t)queue
{
	NSParameterAssert(coalescingPeriod > 0.);
	NSParameterAssert(queue != nil);

	self = [super init];
	if (self)
	{
		_coalescingPeriod = coalescingPeriod;
		_timerLock = [NSObject new];

		_timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
		_resumed = NO;
		if (!_timer)
		{
			return nil;
		}

		weakify(self);
		dispatch_source_set_event_handler(_timer, ^{
			strongify(self);

			dispatch_block_t block = self.actualBlock;
			if (block)
			{
				block();
			}
		});
	}
	return self;
}

- (void)dispatchCoalescedBlock:(dispatch_block_t)block
{
	NSParameterAssert(block != nil);

	@synchronized (self.timerLock)
	{
		self.actualBlock = block;

		dispatch_time_t startTime = dispatch_walltime(NULL, self.coalescingPeriod * NSEC_PER_SEC);
		dispatch_source_set_timer(self.timer, startTime, DISPATCH_TIME_FOREVER, DelayedExecutorLeeway);

		if (!self.resumed)
		{
			dispatch_resume(self.timer);
			self.resumed = YES;
		}
	}
}

- (void)cancelTimer
{
	@synchronized (self.timerLock)
	{
		if (!self.timer)
		{
			return;
		}

		if (!self.resumed)
		{
			// Библиотека lib dispatch требует обязательного вызова resume на таймере перед его освобождением,
			// иначе будет креш
			// Library (lib dispatch) must call (resume) operation on timer before (cancel).
			dispatch_resume(self.timer);
		}
		dispatch_source_cancel(self.timer);
		self.timer = nil;
	}
}

@end
