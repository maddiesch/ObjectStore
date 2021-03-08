//
//  ObjectManagerHelper.swift
//  
//
//  Created by Maddie Schipper on 2/27/21.
//

import Foundation
import CoreData
import Combine

fileprivate let objectManagerFinalizeQueue = DispatchQueue(label: "dev.schipper.ObjectManager-FinishingQueue", attributes: .concurrent, autoreleaseFrequency: .workItem)

fileprivate protocol _BackgroundResultReceiver {
    associatedtype ValueType
    
    func send(_ value: ValueType)
    
    func fail(_ error: Error)
}

fileprivate class _BackgroundResultPublisher<ResultType> : Publisher, _BackgroundResultReceiver {
    typealias Output = ResultType
    
    typealias Failure = Error
    
    private var value: ResultType?
    private var error: Error?
    
    private final class _Subscription : Subscription, _BackgroundResultReceiver {
        private var subscriber: AnySubscriber<Output, Failure>?
        private var requested: Subscribers.Demand = .none
        
        init(subscriber: AnySubscriber<Output, Failure>) {
            self.subscriber = subscriber
        }
        
        func request(_ demand: Subscribers.Demand) {
            self.requested += demand
        }
        
        func cancel() {
            self.subscriber = nil
        }
        
        fileprivate func send(_ value: ResultType) {
            defer {
                self.subscriber?.receive(completion: .finished)
            }
            
            guard self.requested > .none else {
                return
            }
            
            self.requested -= .max(1)
            self.requested += self.subscriber?.receive(value) ?? .none
            self.subscriber?.receive(completion: .finished)
        }
        
        fileprivate func fail(_ error: Error) {
            self.subscriber?.receive(completion: .failure(error))
        }
    }
    
    func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
        let subscription = _Subscription(subscriber: AnySubscriber(subscriber))
        
        subscriber.receive(subscription: subscription)
        
        if let v = self.value {
            subscription.send(v)
        } else if let err = self.error {
            subscription.fail(err)
        }
        
        self.receivers.append(subscription)
    }
    
    private var receivers = Array<_Subscription>()
    
    fileprivate func send(_ value: ResultType) {
        self.value = value
        
        for rec in self.receivers {
            rec.send(value)
        }
    }
    
    fileprivate func fail(_ error: Error) {
        self.error = error
        
        for rec in self.receivers {
            rec.fail(error)
        }
    }
}

extension ObjectManager {
    public func inBackground<ResultType>(_ block: @escaping (NSManagedObjectContext) throws -> ResultType) -> AnyPublisher<ResultType, Error> {
        let publisher = _BackgroundResultPublisher<ResultType>()
        
        let context = self.container.newBackgroundContext()
        
        context.perform {
            do {
                let result = try block(context)
                
                publisher.send(result)
            } catch {
                publisher.fail(error)
            }
        }
        
        return publisher.receive(on: objectManagerFinalizeQueue).eraseToAnyPublisher()
    }
}

extension Publisher {
    public func inBackgroundContext<Result>(for manager: ObjectManager, block: @escaping (NSManagedObjectContext, Self.Output) throws -> Result) -> AnyPublisher<Result, Error> where Self.Failure == Error {
        return Publishers.FlatMap(upstream: self, maxPublishers: .unlimited) { output -> AnyPublisher<Result, Error> in
            return manager.inBackground { (context) -> Result in
                return try block(context, output)
            }
        }.eraseToAnyPublisher()
    }
}
