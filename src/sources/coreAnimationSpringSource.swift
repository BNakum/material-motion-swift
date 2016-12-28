/*
 Copyright 2016-present The Material Motion Authors. All Rights Reserved.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import Foundation

/**
 Create a core animation spring source for a Spring plan.

 Only works with Subtractable types due to use of additive animations.
 */
@available(iOS 9.0, *)
public func coreAnimationSpringSource<T where T: Subtractable, T: Zeroable>(_ spring: Spring<T>) -> MotionObservable<T> {
  return MotionObservable { observer in
    let animation = CASpringAnimation()

    let configuration = spring.configuration.read()
    animation.damping = configuration.friction
    animation.stiffness = configuration.tension

    animation.isAdditive = true

    let destinationSubscription = spring.destination.subscribe {
      let from = spring.initialValue.read()
      let to = $0
      let delta = from - to
      animation.fromValue = delta
      animation.toValue = T.zero()
      animation.duration = animation.settlingDuration

      observer.state(.active)
      CATransaction.begin()
      CATransaction.setCompletionBlock {
        observer.state(.atRest)
      }

      observer.next($0)
      observer.coreAnimation(animation)

      CATransaction.commit()
    }

    return {
      destinationSubscription.unsubscribe()
    }
  }
}
