import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { BaseHttpService } from 'src/app/shared/base-http.service';

@Injectable({
  providedIn: 'root',
})
export class ExpressionApiService extends BaseHttpService {
  constructor(http: HttpClient) {
    super(http);
  }
}
