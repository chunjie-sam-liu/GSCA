import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { MethyComponent } from './methy.component';

describe('MethyComponent', () => {
  let component: MethyComponent;
  let fixture: ComponentFixture<MethyComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ MethyComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(MethyComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
