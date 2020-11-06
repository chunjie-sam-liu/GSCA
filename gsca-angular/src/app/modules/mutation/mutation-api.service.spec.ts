import { TestBed } from '@angular/core/testing';

import { MutationApiService } from './mutation-api.service';

describe('MutationApiService', () => {
  let service: MutationApiService;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(MutationApiService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});
