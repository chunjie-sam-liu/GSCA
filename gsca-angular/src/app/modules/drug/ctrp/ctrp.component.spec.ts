import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { CtrpComponent } from './ctrp.component';

describe('CtrpComponent', () => {
  let component: CtrpComponent;
  let fixture: ComponentFixture<CtrpComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ CtrpComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(CtrpComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
