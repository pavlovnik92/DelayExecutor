//
//  DelayExecutor.h
//  DelayExecutor
//
//  Created by Nikita Pavlov on 03.10.2020.
//

@import Foundation;

//! Project version number for DelayExecutor.
FOUNDATION_EXPORT double DelayExecutorVersionNumber;

//! Project version string for DelayExecutor.
FOUNDATION_EXPORT const unsigned char DelayExecutorVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <DelayExecutor/PublicHeader.h>

/**
 Класс позволяет отсрочить вызов блока на указанный период времени.
 Что позволяет объединить множество частых вызовов в один за указанный период времени.
 This class allow to delay call last active block. It's useful, if you have many equals actions and you want to call last action.

 @discussion Каждый раз, когда происходит отправка блока на исполнение, класс LNSDelayedExecutor
 засекает указанный промежуток времени и запоминает переданный блок (класс всегда запоминает только
 последний переданный блок). По истечению периода времени последний переданный блок выполняется на заданной очереди.
 */
@interface DelayExecutor : NSObject

@property (nonatomic, readonly) NSTimeInterval coalescingPeriod;  /**< Период отсрочки исполнения. */

/**
 Инициализирует новую инстанцию класса.

 @param coalescingPeriod Период отсрочки исполнения блоков.
 @param queue Очередь, на которой будет исполнен блок после указанного периода времени.
 @return Инициализированный объект.
 */
- (instancetype)initWithCoalescingPeriod:(NSTimeInterval)coalescingPeriod queue:(dispatch_queue_t)queue;

/**
 Отправить блок на отложенное исполнение.
 Sent block to delay execution

 @param block Блок для отложенного исполнения.
 */
- (void)dispatchCoalescedBlock:(dispatch_block_t)block;

@end


