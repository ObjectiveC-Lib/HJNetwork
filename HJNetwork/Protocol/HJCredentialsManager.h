//
//  HJCredentialsManager.h
//  HJNetwork
//
//  Created by navy on 2022/5/30.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*! Manages the list of trusted anchor certificates.  This class is thread
 *  safe.
 */
@interface HJCredentialsManager : NSObject

///< The list of trusted anchor certificates elements are of type SecCertificateRef; observable.
@property (atomic, copy, readonly ) NSArray *trustedAnchors;

- (instancetype)init;

/*! Adds a certificate to the end of the list of trusted anchor certificates.
 *  Does nothing if the certificate is already in the list.
 *  \param newAnchor The certificate to add; must not be NULL.
 */
- (void)addTrustedAnchor:(SecCertificateRef)newAnchor;

@end

NS_ASSUME_NONNULL_END
